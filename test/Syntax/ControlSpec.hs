module Syntax.ControlSpec where

import Syntax.Tree
import Syntax.ParseState as S
import Syntax.Bexp
import Syntax.Variable
import Syntax.Parser
import Syntax.Common
import Test.Hspec
import Test.Hspec.Megaparsec
import TestHelper.Parser
import Text.Megaparsec (parse)

controlSpec :: Spec
controlSpec = do
    ifStmSpec
    whileSpec

ifStmSpec :: Spec
ifStmSpec = describe "ifStm" $ do
    let state = S.fromVarList [("tape", TapeType)]

    context "parsing a single IF" $ do
        it "parses IF" $ do
            parseEvalState state program "" "if True { right tape }" `shouldParseStm` (If TRUE (MoveRight "tape") [] Nothing)

        it "fails to parse if a boolean expression is missing" $ do
            parseEvalState state program "" `shouldFailOn` "if { right tape }"

        it "fails to parse if the first brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True right tape }"

        it "fails to parse if the second brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True { right tape"

        it "fails to parse if both braces are missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True right tape"

    context "parsing an IF-ELSEIF" $ do
        it "parses with a single ELSE-IF clause" $ do
            let str      = "if True { right tape } else if False { left tape }"
                expected = If TRUE (MoveRight "tape") [(FALSE, (MoveLeft "tape"))] Nothing
            parseEvalState state program "" str `shouldParseStm` expected

        it "parses with multiple ELSE-IF clauses" $ do
            let str      = "if True { right tape } else if False { left tape } else if True { accept }"
                expected = If TRUE (MoveRight "tape") [(FALSE, (MoveLeft "tape")), (TRUE, Accept)] Nothing
            parseEvalState state program "" str `shouldParseStm` expected

        it "fails to parse if ELSE-IF is before IF" $ do
            parseEvalState state program "" `shouldFailOn` "else if True { right tape } if True right tape }"

        it "fails to parse if the first brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True { right tape } else if True right tape }"

        it "fails to parse if the second brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True { right tape } else if True { right tape"

        it "fails to parse if both braces are missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True { right tape } else if True right rape"

    context "parsing an ELSE clause" $ do
        it "parses ELSE with just an IF" $ do
            let str      = "if True { right tape } else { left tape }"
                expected = If TRUE (MoveRight "tape") [] (Just (MoveLeft "tape"))
            parseEvalState state program "" str `shouldParseStm` expected

        it "parses ELSE with a preceding ELSE-IF" $ do
            let str      = "if True { right tape } else if False { left tape } else { accept }"
                expected = If TRUE (MoveRight "tape") [(FALSE, (MoveLeft "tape"))] (Just Accept)
            parseEvalState state program "" str `shouldParseStm` expected

        it "fails to parse if the ELSE is before IF" $ do
            parseEvalState state program "" `shouldFailOn` "else { accept } if { left tape }"

        it "fails to parse if the first brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True { right tape } else right tape }"

        it "fails to parse if the second brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True { right tape } else { right tape"

        it "fails to parse if both braces are missing" $ do
            parseEvalState state program "" `shouldFailOn` "if True { right tape } else right tape"

    context "identifier scope" $ do
        it "allows variables to be shadowed" $ do
            let innerVarDecl = VarDecl "x" (Literal 'a')
                ifStatement  = If TRUE innerVarDecl [] Nothing
                outerVarDecl = TapeDecl "x" "xyz"
                comp         = Comp outerVarDecl ifStatement
            parseEvalState state program "" "let x = \"xyz\" \n if True { let x = 'a' }" `shouldParseStm` comp

        it "allows the types of variables to be changed at inner scopes" $ do
            let innerVarDecl = VarDecl "x" (Literal 'a')
                write        = Write "tape" (Var "x")
                body         = Comp innerVarDecl write
                ifStatement  = If TRUE body [] Nothing
                outerVarDecl = TapeDecl "x" "xyz"
                comp         = Comp outerVarDecl ifStatement
            parseEvalState state program "" "let x = \"xyz\" \n if True { let x = 'a' \n write tape x }" `shouldParseStm` comp

        it "reverts variables after scope is exited" $ do
            let innerVarDecl = VarDecl "x" (Literal 'a')
                ifStatement  = If TRUE innerVarDecl [] Nothing
                outerVarDecl = TapeDecl "x" "xyz"
                write        = Write "x" (Literal 'a')
                comp         = Comp outerVarDecl (Comp ifStatement write)
            parseEvalState state program "" "let x = \"xyz\" \n if True { let x = 'a' } \n write x 'a'" `shouldParseStm` comp

whileSpec :: Spec
whileSpec = do
    describe "while" $ do
        let state = S.fromVarList [("tape", TapeType)]

        it "parses WHILE" $ do
            parseEvalState state program "" "while True { right tape }" `shouldParseStm` (While TRUE (MoveRight "tape"))

        it "fails to parse if a boolean expression is missing" $ do
            parseEvalState state program "" `shouldFailOn` "while { right tape }"

        it "fails to parse if the first brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "while True right tape }"

        it "fails to parse if the second brace is missing" $ do
            parseEvalState state program "" `shouldFailOn` "while True { right tape"

        it "fails to parse if both braces are missing" $ do
            parseEvalState state program "" `shouldFailOn` "while True right tape"

        context "identifier scope" $ do
            it "allows variables to be shadowed" $ do
                let innerVarDecl = VarDecl "x" (Literal 'a')
                    while        = While TRUE innerVarDecl
                    outerVarDecl = TapeDecl "x" "xyz"
                    comp         = Comp outerVarDecl while
                parseEvalState state program "" "let x = \"xyz\" \n while True { let x = 'a' }" `shouldParseStm` comp

            it "allows the types of variables to be changed at inner scopes" $ do
                let innerVarDecl = VarDecl "x" (Literal 'a')
                    write        = Write "tape" (Var "x")
                    body         = Comp innerVarDecl write
                    while        = While TRUE body
                    outerVarDecl = TapeDecl "x" "xyz"
                    comp         = Comp outerVarDecl while
                parseEvalState state program "" "let x = \"xyz\" \n while True { let x = 'a' \n write tape x }" `shouldParseStm` comp

            it "reverts variables after scope is exited" $ do
                let innerVarDecl = VarDecl "x" (Literal 'a')
                    while        = While TRUE innerVarDecl
                    outerVarDecl = TapeDecl "x" "xyz"
                    write        = Write "x" (Literal 'a')
                    comp         = Comp outerVarDecl (Comp while write)
                parseEvalState state program "" "let x = \"xyz\" \n while True { let x = 'a' } \n write x 'a'" `shouldParseStm` comp
