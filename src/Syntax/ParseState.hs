module Syntax.ParseState
( module Syntax.ParseState
, module Text.Megaparsec.String
)
where

import Syntax.Tree
import qualified Syntax.Env as E
import Control.Monad.State.Lazy (StateT, modify, get)
import Text.Megaparsec.String

-- Types that can be declared. Used to keep track of identifiers while parsing.
data EnvDecl = PVar DataType
             | PFunc [DataType]
             | PStruct [StructMemberVar]
             deriving (Eq, Show)

-- Keeps track of what identifiers, and their associated types, have been
-- parsed so far.
type ParseState = E.Env EnvDecl
type ParserM = StateT ParseState Parser

-- Adds a variable name to the current scope.
putM :: Identifier -> EnvDecl -> ParserM ()
putM i v = modify (E.put i v)

-- Attemps to retrieve the declaration using the identifier. If fails produces
-- an error stating that the definition does not exist.
tryEnvDecl :: Maybe EnvDecl -> ParserM EnvDecl
tryEnvDecl e = do
    case e of
        Nothing -> fail $ (show e) ++ " does not exist"
        Just x  -> return x

-- Returns whether a identifier can be used, i.e. if the identifier has been
-- declared in this scope or the scope above.
getM :: Identifier -> ParserM EnvDecl
getM i = do
    state <- get
    tryEnvDecl (E.get i state)

-- Returns the type of a member variable of a struct, if both the struct and
-- variable exist.
getStructMember :: StructName -> VarName -> ParserM (Maybe DataType)
getStructMember = undefined

-- Retrive the identifier from the environment and modify it. If the identifier
-- does not exist then the supplied env is returned.
modifyM :: Identifier -> (EnvDecl -> EnvDecl) -> ParserM ()
modifyM i f = modify (E.modify i f)

-- Moves any used names into the scope above.
descendScopeM :: ParserM ()
descendScopeM = modify E.descendScope

-- Returns whether a identifier has already been used to declare a variable/function.
-- i.e. if the name is in use at this scope.
isTakenM :: Identifier -> ParserM Bool
isTakenM i = do
    state <- get
    return (E.isTaken i state)
