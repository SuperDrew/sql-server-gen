{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GADTs #-}

module Database.SqlServer.Definition.Procedure
       (
         Procedure,
         parameters,
         procedureName
       ) where

import Database.SqlServer.Definition.Identifier hiding (unwrap)
import Database.SqlServer.Definition.DataType
import Database.SqlServer.Definition.Entity

import Test.QuickCheck
import Data.DeriveTH
import Text.PrettyPrint

data Parameter = Parameter
  {
    parameterName :: ParameterIdentifier
  , dataType      :: Type
  , isOutput      :: Bool
  }

derive makeArbitrary ''Parameter

renderOut :: Bool -> Doc
renderOut True = text "OUTPUT"
renderOut False = empty

renderParameter :: Parameter -> Doc
renderParameter p = renderParameterIdentifier (parameterName p) <+> renderDataType (dataType p) <+> renderOut (isOutput p)

data Procedure = Procedure
  {
    procedureName :: RegularIdentifier
  , parameters    :: [Parameter]
  }

derive makeArbitrary ''Procedure

-- Generating arbitrary SQL is perhaps a bit complicated.
statementBody :: String
statementBody = "select 1\n"

instance Entity Procedure where
  name = procedureName
  toDoc p = text "CREATE PROCEDURE" <+> renderName p $+$
                              hcat (punctuate comma (map renderParameter (parameters p))) <+> text "AS" $+$
                              text statementBody $+$
                              text "GO"
                              
