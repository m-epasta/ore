default: build

build:
    @odin build .

test:
   @odin test tests

clean:
    @rm *bin
    @rm ore
