{-# LANGUAGE ScopedTypeVariables #-}

import qualified Data.Map as M
import Data.Maybe
import qualified Data.Vector.Storable as SV
import Control.Error
import Control.Monad
import Foreign.C

import Data.NetCDF
import Data.NetCDF.Vector

main :: IO ()
main = do
  let xdim = NcDim "x" 10 False
      ydim = NcDim "y" 10 False
      nc = emptyNcInfo "tst-put.nc" #
           addNcDim xdim #
           addNcDim ydim #
           addNcVar (NcVar "x" NcDouble [xdim] M.empty) #
           addNcVar (NcVar "y" NcDouble [ydim] M.empty) #
           addNcVar (NcVar "z" NcDouble [xdim, ydim] M.empty)
  let write nc = do
        let xvar = fromJust $ ncVar nc "x"
            yvar = fromJust $ ncVar nc "y"
            zvar = fromJust $ ncVar nc "z"
        put nc xvar $ SV.fromList [1..10 :: CDouble]
        put nc yvar $ SV.fromList [1..10 :: CDouble]
        put nc zvar $ SV.fromList [ 100 * x + y |
                                    x <- [1..10 :: CDouble],
                                    y <- [1..10 :: CDouble] ]
        return ()
  withCreateFile nc write (putStrLn . ("ERROR: " ++) . show)
