{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GADTs #-}

module Database.SqlServer.Definition.Function
       (
         Function
       ) where

import Database.SqlServer.Definition.Identifier hiding (unwrap)
import Database.SqlServer.Definition.DataType
import Database.SqlServer.Definition.Value
import Database.SqlServer.Definition.Entity

import Test.QuickCheck
import Data.DeriveTH
import Text.PrettyPrint
import Data.Maybe (fromJust, isJust)
import Control.Monad

data NullOption = ReturnsNullOnNullInput
                | CalledOnNullInput

derive makeArbitrary ''NullOption

renderNullOption :: NullOption -> Doc
renderNullOption ReturnsNullOnNullInput = text "RETURNS NULL ON NULL INPUT"
renderNullOption CalledOnNullInput = text "CALLED ON NULL INPUT"

data FunctionOption = FunctionOption
    {
      encryption :: Bool
    , schemaBinding :: Bool
    , nullOption :: Maybe NullOption
    }

derive makeArbitrary ''FunctionOption

areThereAnyOptionsSet :: FunctionOption -> Bool
areThereAnyOptionsSet f = encryption f || schemaBinding f || isJust (nullOption f)

renderFunctionOptions :: FunctionOption -> Doc
renderFunctionOptions f
  | not (areThereAnyOptionsSet f) = empty
  | otherwise = text "WITH" <+>
                vcat (punctuate comma
                  (filter (/= empty) [ if encryption f then text "ENCRYPTION" else empty
                                     , if schemaBinding f then text "SCHEMABINDING" else empty
                                     , maybe empty renderNullOption (nullOption f) ]))

newtype InputType = InputType Type

-- A time stamp can not be passed in as an argument to a function
instance Arbitrary InputType where
  arbitrary = liftM InputType $ arbitrary `suchThat` (not . isTimestamp)

renderInputDataType :: InputType -> Doc
renderInputDataType (InputType t) = renderDataType t

data Parameter = Parameter
  {
    parameterName :: ParameterIdentifier
  , dataType      :: InputType
  }

renderParameter :: Parameter -> Doc
renderParameter p = renderParameterIdentifier (parameterName p) <+> renderInputDataType (dataType p) 

derive makeArbitrary ''Parameter

data ReturnType = ReturnType Type SQLValue

instance Arbitrary ReturnType where
  arbitrary = do
    t <- arbitrary `suchThat` (\x -> isJust $ value x)
    v <- fromJust $ value t
    return (ReturnType t v)

renderReturnType :: ReturnType -> Doc
renderReturnType (ReturnType t _) = renderDataType t

-- Safe because of instance of Arbitrary above
renderReturnValue :: ReturnType -> Doc
renderReturnValue (ReturnType _ v) = renderValue v

data ScalarFunction = ScalarFunction
   {
     scalarFunctionName :: RegularIdentifier
   , parameters :: [Parameter]
   , returnType :: ReturnType
   , functionOption :: FunctionOption
   }

derive makeArbitrary ''ScalarFunction

data Function = ScalarFunctionC ScalarFunction

derive makeArbitrary ''Function

instance Entity Function where
  name (ScalarFunctionC f) = scalarFunctionName f
  toDoc fn@(ScalarFunctionC f) = text "CREATE FUNCTION" <+> renderName fn <+>
                              parens (hcat (punctuate comma (map renderParameter (parameters f)))) $+$
                              text "RETURNS" <+> renderReturnType (returnType f) $+$
                              renderFunctionOptions (functionOption f) $+$
                              text "AS" $+$
                              text "BEGIN" $+$
                              text "RETURN" <+> renderReturnValue (returnType f) $+$
                              text "END" $+$ text "GO\n"

instance Show Function where
  show f = show (toDoc f)
