default: check

check:
    @odin check . -no-entry-point

test:
   @odin test tests

clean:
    @rm *bin
    @rm ore
