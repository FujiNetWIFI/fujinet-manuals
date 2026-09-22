#!/usr/bin/env python3
"""
snipcheck.py --- assemble every 6809 snippet printed in the book.

Each `asm:` example, each #asmbox and the assembly half of each #pair and
#vpair is pulled out of manual.typ and handed to lwasm with fn.inc in
front of it.  Snippets are fragments, so they reference labels that live
in the program around them; those are discovered from lwasm's own
"Undefined symbol" complaints and stubbed, and the assembler is run again.
Anything that survives that is a real error --- a bad mnemonic, an
addressing mode the 6809 does not have, an operand that will not parse.

C snippets are fragments in the same way but cannot be stubbed the same
way, so they are checked for balanced delimiters only.  The complete C
programs are compiled for real by `make listings`.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
MANUAL = HERE / "manual.typ"
FNLIB = HERE / "listings" / "fnlib"

# Names lwasm will not complain about but we should not stub either.
REGISTERS = {"a", "b", "d", "x", "y", "u", "s", "pc", "cc", "dp"}


def read_typst_string(text, i):
    """text[i] is an opening quote.  Return (value, index past the close)."""
    assert text[i] == '"'
    i += 1
    out = []
    while i < len(text):
        c = text[i]
        if c == "\\":
            nxt = text[i + 1]
            out.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(nxt, nxt))
            i += 2
            continue
        if c == '"':
            return "".join(out), i + 1
        out.append(c)
        i += 1
    raise ValueError("unterminated string")


def snippets(text, openers):
    """Yield every string literal that follows one of the opener patterns."""
    for pat in openers:
        for m in re.finditer(pat, text):
            i = m.end() - 1
            while text[i] != '"':
                i += 1
            value, _ = read_typst_string(text, i)
            yield value


def asm_snippets(text):
    seen = []
    seen += list(snippets(text, [r'\basm:\s*"', r'#asmbox\(\s*"']))
    # the assembly half is the first argument of pair() and vpair()
    for m in re.finditer(r"#v?pair\(\s*\n?\s*\"", text):
        i = m.end() - 1
        value, _ = read_typst_string(text, i)
        seen.append(value)
    return seen


def c_snippets(text):
    out = list(snippets(text, [r'#cbox\(\s*"']))
    for m in re.finditer(r'\bc:\s*"', text):
        i = m.end() - 1
        value, _ = read_typst_string(text, i)
        out.append(value)
    return out


def clean(body):
    """Drop the book's elisions, which are prose and not code."""
    out = []
    for line in body.splitlines():
        t = line.strip()
        if t.startswith("..."):
            continue
        out.append(line)
    return "\n".join(out)


def is_cmoc_inline(body):
    """CMOC inline assembly uses @labels and is checked by make listings."""
    return any(l.lstrip().startswith("@") for l in body.splitlines())


MNEMONICS = set("""
abx adca adcb adda addb addd anda andb andcc asl asla aslb asr asra asrb
bcc bcs beq bge bgt bhi bhs bita bitb ble blo bls blt bmi bne bpl bra brn
bsr bvc bvs clr clra clrb cmpa cmpb cmpd cmps cmpu cmpx cmpy com coma comb
cwai daa dec deca decb eora eorb exg inc inca incb jmp jsr lbcc lbcs lbeq
lbge lbgt lbhi lbhs lble lblo lbls lblt lbmi lbne lbpl lbra lbrn lbsr lbvc
lbvs lda ldb ldd lds ldu ldx ldy leas leau leax leay lsl lsla lslb lsr lsra
lsrb mul neg nega negb nop ora orb orcc puls pulu pshs pshu rol rola rolb
ror rora rorb rti rts sbca sbcb sex sta stb std sts stu stx sty suba subb
subd swi swi2 swi3 sync tfr tst tsta tstb
equ fcb fcc fdb fqb rmb org end include setdp align fill zmb ifne ifeq
endc else error pragma section endsection export extern import
""".split())


def fninc_symbols():
    text = (FNLIB / "fn.inc").read_text()
    return {m.group(1) for m in
            re.finditer(r"^([A-Za-z_][A-Za-z0-9_]*)\s+EQU\b", text, re.M)}


KNOWN = None


def identifiers(lines):
    out = []
    for line in lines:
        line = re.sub(r"[;*].*$", "", line)
        for tok in re.findall(r"[@A-Za-z_][A-Za-z0-9_.$]*", line):
            if tok.lower() in MNEMONICS or tok.lower() in REGISTERS:
                continue
            out.append(tok)
    return out


def remaining_error(out, stubs):
    """What is left after stubbing, minus the stubbing's own artifacts.

    A fragment's branch targets live in the program around it.  Stubbing
    them at the end of the snippet can put them more than 127 bytes away
    --- past an rmb 256, say --- and an 8-bit immediate cannot hold an
    address at all.  Both come out as "Byte overflow" and neither is
    anything to do with the book, so a byte overflow on a line that
    mentions a stubbed name is forgiven.  Everything else is real.
    """
    lines = out.splitlines()
    real = []
    for i, line in enumerate(lines):
        if "ERROR" not in line:
            continue
        echo = lines[i + 1] if i + 1 < len(lines) else ""
        if "Byte overflow" in line and any(t in echo for t in stubs):
            continue
        real.append(line)
    if not real:
        return None
    return "\n".join(real[:6])


def assemble(body, workdir):
    """Assemble body, stubbing the symbols the surrounding program owns.

    The stubs go *after* the code and resolve to the location counter, so
    a branch to one is a short forward branch and stays in range.  Putting
    them at zero would fail every relative branch in the book for reasons
    that have nothing to do with the book.

    lwasm reports an undefined symbol in a branch as a byte overflow --- it
    takes the value as zero and then the offset will not fit --- so when
    there is nothing new to stub, the offending source lines are mined for
    identifiers and those are stubbed instead.
    """
    global KNOWN
    if KNOWN is None:
        KNOWN = fninc_symbols()

    stubs = []
    include = True
    for _ in range(60):
        src = workdir / "snip.asm"
        src.write_text(
            ('        INCLUDE "fn.inc"\n' if include else "")
            + "        ORG     $3F00\n"
            + body.rstrip()
            + "\n"
            + "".join("%-7s EQU     *\n" % t for t in stubs)
            + "        END\n"
        )
        r = subprocess.run(
            ["lwasm", "--6809", "--pragma=forwardrefmax",
             "-I", str(FNLIB), "-o", "/dev/null", str(src)],
            capture_output=True, text=True,
        )
        if r.returncode == 0:
            return None
        out = r.stdout + r.stderr

        # a snippet that carries its own equates clashes with fn.inc
        if include and "Multiply defined symbol" in out:
            include = False
            continue

        undef = re.findall(r"Undefined symbol \(?([@A-Za-z_][A-Za-z0-9_.$]*)",
                           out)
        fresh = [u for u in dict.fromkeys(undef)
                 if u not in stubs and u.lower() not in REGISTERS]

        if not fresh:
            # mine the echoed source lines for names we have not stubbed
            echoed = [l.split(":", 2)[-1] for l in out.splitlines()
                      if re.match(r"^\S+:\d+", l)]
            local = {m.group(1) for m in
                     re.finditer(r"^([@A-Za-z_][A-Za-z0-9_.$]*)",
                                 body, re.M)}
            fresh = [t for t in dict.fromkeys(identifiers(echoed))
                     if t not in stubs and t not in KNOWN and t not in local]

        if not fresh:
            return remaining_error(out, stubs)
        stubs.extend(fresh)
    return "gave up stubbing symbols"


def balanced(s):
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    instr = None
    i = 0
    while i < len(s):
        c = s[i]
        if instr:
            if c == "\\":
                i += 2
                continue
            if c == instr:
                instr = None
        elif c in "\"'":
            instr = c
        elif c in "([{":
            stack.append(c)
        elif c in ")]}":
            if not stack or stack.pop() != pairs[c]:
                return False
        i += 1
    return not stack


def main():
    text = MANUAL.read_text()
    asm = asm_snippets(text)
    cs = c_snippets(text)

    bad = 0
    skipped = []
    with tempfile.TemporaryDirectory() as td:
        work = Path(td)
        for n, body in enumerate(asm, 1):
            body = clean(body)
            # a snippet that is nothing but comments has nothing to check
            if not any(l.strip() and not l.strip().startswith(("*", ";"))
                       for l in body.splitlines()):
                continue
            if is_cmoc_inline(body):
                skipped.append(n)
                continue
            err = assemble(body, work)
            if err:
                bad += 1
                print("snipcheck: assembly snippet %d does not assemble:" % n)
                for line in body.splitlines()[:4]:
                    print("    |", line)
                for line in err.splitlines():
                    print("   ", line)

    unbal = 0
    for n, body in enumerate(cs, 1):
        if not balanced(body):
            unbal += 1
            print("snipcheck: C snippet %d has unbalanced delimiters:" % n)
            for line in body.splitlines()[:4]:
                print("    |", line)

    if bad or unbal:
        print("snipcheck: %d assembly and %d C problem(s)" % (bad, unbal))
        return 1

    note = ""
    if skipped:
        note = " (%d CMOC inline blocks left to make listings)" % len(skipped)
    print("snipcheck: %d assembly snippets assemble, %d C snippets balanced: ok%s"
          % (len(asm) - len(skipped), len(cs), note))
    return 0


if __name__ == "__main__":
    sys.exit(main())
