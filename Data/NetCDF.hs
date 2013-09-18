-- | Bindings to the Unidata NetCDF data access library.
--
--   As well as conventional low-level FFI bindings to the functions
--   in the NetCDF library (in the "Data.NetCDF.Raw" modules),
--   @hnetcdf@ provides a higher-level Haskell interface (currently
--   only for reading data).  This higher-level interface aims to
--   provide a "container polymorphic" view of NetCDF data allowing
--   NetCDF variables to be read into @Storable@ @Vectors@ and Repa
--   arrays easily.
--
--   For example:
--
-- > import Data.NetCDF
-- > import Foreign.C
-- > import qualified Data.Vector.Storable as SV
-- > ...
-- > type SVRet = IO (Either NcError (SV.Vector a))
-- > ...
-- >   enc <- openFile "tst.nc" ReadMode
-- >   case enc of
-- >     Right nc -> do
-- >       eval <- get nc "varname" :: SVRet CDouble
-- >       ...
--
--   gets the full contents of a NetCDF variable as a @Storable@
--   @Vector@, while the following code reads the same variable
--   (assumed to be three-dimensional) into a Repa array:
--
-- > import Data.NetCDF
-- > import Foreign.C
-- > import qualified Data.Array.Repa as R
-- > import qualified Data.Array.Repa.Eval as RE
-- > import Data.Array.Repa.Repr.ForeignPtr (F)
-- > ...
-- > type RepaRet3 a = IO (Either NcError (R.Array F R.DIM3 a))
-- > ...
-- >   enc <- openFile "tst.nc" ReadMode
-- >   case enc of
-- >     Right nc -> do
-- >       eval <- get nc "varname" :: RepaRet3 CDouble
-- >       ...

module Data.NetCDF
       ( module Data.NetCDF.Types
       , module Data.NetCDF.Metadata
       , NcStorable (..)
       , IOMode (..)
       , openFile, closeFile, withFile
       , get1, get, getA, getS ) where

import Data.NetCDF.Raw
import Data.NetCDF.Types
import Data.NetCDF.Metadata
import Data.NetCDF.PutGet
import Data.NetCDF.Storable
import Data.NetCDF.Store
import Data.NetCDF.Utils

import Control.Applicative ((<$>))
import Control.Exception (bracket)
import Control.Monad (forM, void)
import Control.Monad.IO.Class
import Control.Monad.Trans.Reader
import Control.Error
import Data.List
import qualified Data.Map as M
import Foreign.C
import System.IO (IOMode (..))

-- | Open a NetCDF file and read all metadata.
openFile :: FilePath -> IOMode -> NcIO NcInfo
openFile p mode = runAccess "openFile" p $ do
  ncid <- chk $ nc_open p (ncIOMode mode)
  (ndims, nvars, nattrs, unlim) <- chk $ nc_inq ncid
  dims <- forM [0..ndims-1] (read1Dim ncid unlim)
  attrs <- forM [0..nattrs-1] (read1Attr ncid ncGlobal)
  vars <- forM [0..nvars-1] (read1Var ncid dims)
  let mkMap nf = foldl (\m v -> M.insert (nf v) v m) M.empty
      dimmap = mkMap ncDimName dims
      attmap = mkMap ncAttrName attrs
      varmap = mkMap ncVarName vars
      varidmap = M.fromList $ zip (map ncVarName vars) [0..]
  return $ NcInfo p dimmap varmap attmap ncid varidmap

-- | Close a NetCDF file.
closeFile :: NcInfo -> IO ()
closeFile (NcInfo _ _ _ _ ncid _) = void $ nc_close ncid

-- | Bracket file use: a little different from the standard 'withFile'
-- function because of error handling.
withFile :: FilePath -> IOMode
         -> (NcInfo -> IO r) -> (NcError -> IO r) -> IO r
withFile p m ok err = bracket
                      (openFile p m)
                      (either (const $ return ()) closeFile)
                      (either err ok)

-- | Read a single value from an open NetCDF file.
get1 :: NcStorable a => NcInfo -> NcVar -> [Int] -> NcIO a
get1 nc var idxs = runAccess "get1" (ncName nc) $
  chk $ get_var1 (ncId nc) ((ncVarIds nc) M.! (ncVarName var)) idxs

-- | Read a whole variable from an open NetCDF file.
get :: (NcStorable a, NcStore s) => NcInfo -> NcVar -> NcIO (s a)
get nc var = runAccess "get" (ncName nc) $ do
  let ncid = ncId nc
      varid = (ncVarIds nc) M.! (ncVarName var)
      sz = map ncDimLength $ ncVarDims var
  chk $ get_var ncid varid sz

-- | Read a slice of a variable from an open NetCDF file.
getA :: (NcStorable a, NcStore s)
     => NcInfo -> NcVar -> [Int] -> [Int] -> NcIO (s a)
getA nc var start count = runAccess "getA" (ncName nc) $ do
  let ncid = ncId nc
      varid = (ncVarIds nc) M.! (ncVarName var)
  chk $ get_vara ncid varid start count

-- | Read a strided slice of a variable from an open NetCDF file.
getS :: (NcStorable a, NcStore s)
     => NcInfo -> NcVar -> [Int] -> [Int] -> [Int] -> NcIO (s a)
getS nc var start count stride = runAccess "getS" (ncName nc) $ do
  let ncid = ncId nc
      varid = (ncVarIds nc) M.! (ncVarName var)
  chk $ get_vars ncid varid start count stride


-- | Helper function to read a single NC dimension.
read1Dim :: Int -> Int -> Int -> Access NcDim
read1Dim ncid unlim dimid = do
  (name, len) <- chk $ nc_inq_dim ncid dimid
  return $ NcDim name len (dimid == unlim)

-- | Helper function to read a single NC attribute.
read1Attr :: Int -> Int -> Int -> Access NcAttr
read1Attr ncid varid attid = do
  n <- chk $ nc_inq_attname ncid varid attid
  (itype, len) <- chk $ nc_inq_att ncid varid n
  a <- readAttr ncid varid n (toEnum itype) len
  return a

-- | Helper function to read metadata for a single NC variable.
read1Var :: Int -> [NcDim] -> Int -> Access NcVar
read1Var ncid dims varid = do
  (n, itype, nvdims, vdimids, nvatts) <- chk $ nc_inq_var ncid varid
  let vdims = map (dims !!) $ take nvdims vdimids
  vattrs <- forM [0..nvatts-1] (read1Attr ncid varid)
  let vattmap = foldl (\m a -> M.insert (ncAttrName a) a m) M.empty vattrs
  return $ NcVar n (toEnum itype) vdims vattmap

-- | Read an attribute from a NetCDF variable with error handling.
readAttr :: Int -> Int -> String -> NcType -> Int -> Access NcAttr
readAttr nc var n NcChar l = readAttr' nc var n l nc_get_att_text
readAttr nc var n NcShort l = readAttr' nc var n l nc_get_att_short
readAttr nc var n NcInt l = readAttr' nc var n l nc_get_att_int
readAttr nc var n NcFloat l = readAttr' nc var n l nc_get_att_float
readAttr nc var n NcDouble l = readAttr' nc var n l nc_get_att_double
readAttr nc var n NcUInt l = readAttr' nc var n l nc_get_att_uint
readAttr _ _ n _ _ = return $ NcAttr n ([0] :: [CInt])

-- | Helper function for attribute reading.
readAttr' :: Show a => Int -> Int -> String -> Int
          -> (Int -> Int -> String -> Int -> IO (Int, [a])) -> Access NcAttr
readAttr' nc var n l rf = NcAttr n <$> (chk $ rf nc var n l)


