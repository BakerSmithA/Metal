module Syntax.Tree where

-- Tape symbol, i.e. a symbol contained in a cell of the machine's tape.
type TapeSymbol = Char

-- Variable name, i.e. reference to a symbol.
type VarName = String

-- Function name.
type FuncName = String

-- Function argument name.
type ArgName = String

-- Types that can be passed to functions.
data DataType = SymType
              | TapeType
              deriving (Eq, Show)

-- Argument to a function.
data FuncDeclArg = FuncDeclArg ArgName DataType deriving (Eq, Show)

-- All the declared arguments to a function.
type FuncDeclArgs = [FuncDeclArg]

-- Argument to a function when invoking.
data FuncCallArg = Derived DerivedValue
                 | TapeLiteral String
                 deriving (Eq, Show)

-- All the arguments passed to a function call.
type FuncCallArgs = [FuncCallArg]

-- Derived value, i.e. either a literal tape symbol, or a symbol read from
-- under the read/write head, or the value of a variable.
data DerivedValue = Read VarName
                  | Var VarName
                  | Literal TapeSymbol
                  deriving (Eq, Show)

-- Syntax tree for boolean expressions.
data Bexp = TRUE
          | FALSE
          | Not Bexp
          | And Bexp Bexp
          | Or Bexp Bexp
          | Eq DerivedValue DerivedValue
          | Le DerivedValue DerivedValue
          | Ne DerivedValue DerivedValue
          deriving (Eq, Show)

-- Syntax tree for statements.
data Stm = MoveLeft VarName
         | MoveRight VarName
         | Write VarName DerivedValue
         | WriteStr VarName [TapeSymbol]
         | Accept
         | Reject
         | If Bexp Stm [(Bexp, Stm)] (Maybe Stm)
         | While Bexp Stm
         | VarDecl VarName DerivedValue
         | TapeDecl VarName String
         | FuncDecl FuncName FuncDeclArgs Stm
         | Call FuncName FuncCallArgs
         | Comp Stm Stm
         | PrintRead VarName
         | PrintStr String
         | DebugPrintTape VarName
         deriving (Eq, Show)

-- Path of a Metal file to be imported.
type ImportPath = String

-- A type that represents a parsed program.
data Program = Program Stm deriving (Eq, Show)
