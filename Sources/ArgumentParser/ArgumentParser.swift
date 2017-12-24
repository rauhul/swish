// 2017© copyright

/*
 * Parsing a line:
  - Read the line
  - Split on args
 */
//https://docs.python.org/3/library/argparse.html


/*
parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('integers', metavar='N', type=int, nargs='+',
                    help='an integer for the accumulator')
parser.add_argument('--sum', dest='accumulate', action='store_const',
                    const=sum, default=max,
                    help='sum the integers (default: find the max)')

args = parser.parse_args()
print(args.accumulate(args.integers))

python prog.py -h
usage: prog.py [-h] [--sum] N [N ...]

Process some integers.

positional arguments:
    N           an integer for the accumulator

optional arguments:
    -h, --help  show this help message and exit
    --sum       sum the integers (default: find the max)


swish xyz.sh
*/


// https://developer.apple.com/documentation/swift/commandline
// CommandLine

public final class ArgumentParser {

    class Argument { }

    let description: String

    init(description: String) {
        self.description = description
    }

}
