DIRS := fnlib netcat mounter weather os9

all clean:
	@for d in $(DIRS); do $(MAKE) --no-print-directory -C $$d $@ || exit 1; done

.PHONY: all clean
