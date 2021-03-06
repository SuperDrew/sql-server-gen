# sql-server-gen

The goal of this package is to generate arbitrary SQL Server databases (in the form of create statements).  The SQL generated by this code should always be valid and run without errors (but warnings are acceptable).

Currently supported (at various degrees of completion) are:
* Tables (including unique, primary key constraints and index options)
* Views (currently only very basic support)
* Sequences
* Procedures
* Functions
* Queues
* Certificates
* Users
* Roles
* Logins
* Full text catalogs
* Full text stoplists
* Credentials
* Message types
* Contracts
* Services
* Broker Priorties
* Partition Functio

Contributers more than welcome (especially if you know enough Haskell to help me simplify the code!).

# Build instructions

Download the Haskell platform (GHC 7.10.2 version available from https://www.haskell.org/platform/).  Clone this project and open up a command prompt in the root directory of the cloned project.  Running the following series of commands ought to get you to a REPL with everything working.

    cabal update
    cabal sandbox init
    cabal install --dependencies-only
    cabal repl

One you've got a REPL, you can now generate different types.

    x <- sample' (arbitrary :: Gen Database)

A `Database` is the top level container, generating a uniquely named database with random amounts of entities.  To see the currently supported object types you can do

    > :i Entity
    *snip*
    instance Entity PartitionFunction
      -- Defined at src\Database\SqlServer\Definition\PartitionFunction.hs:66:10
    instance Entity BrokerPriority
      -- Defined at src\Database\SqlServer\Definition\BrokerPriority.hs:58:10
    instance Entity MessageType
      -- Defined at src\Database\SqlServer\Definition\MessageType.hs:47:10
    instance Entity Credential
      -- Defined at src\Database\SqlServer\Definition\Credential.hs:46:10
    instance Entity Function
      -- Defined at src\Database\SqlServer\Definition\Function.hs:100:10

Using `generateExamples` and `saveExamples` you can have an interactive session to target particular SQL Server object types.  For example.

    > generateExamples 100 (arbitrary :: Table) >>= saveExamples "foo.sql"

Will create a file called `foo.sql` containing 100 tables of increasing complexity.

If you want more control, then you can use `generateEntity`

    > generateEntity (Options { size = 100, seed = 22 }) :: Certificate
    
# Usage

There's a command line interface you can use too, which will generate arbitrary database definitions.  You might use this to build automated performance tests or soak tests.

    cabal build cli
    ./cli --help    

Should produce the documentation.  
