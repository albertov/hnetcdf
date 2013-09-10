{-# LANGUAGE MultiParamTypeClasses, TypeFamilies #-}
module Data.NetCDF.Storable
       ( NcStorable (..)
       , withSizeArray
       , put_var1 , put_var, put_vara, put_vars
       , get_var1 , get_var, get_vara, get_vars
       ) where

import Foreign.C
import Foreign.Ptr
import Foreign.ForeignPtr
import Foreign.Storable
import Foreign.Marshal.Array
import Foreign.Marshal.Alloc
import Control.Applicative ((<$>))
import Control.Monad (liftM)
import Data.Word

import Data.NetCDF.Types
import Data.NetCDF.Store
import Data.NetCDF.Raw.PutGet

withSizeArray :: (Storable a, Integral a) => [a] -> (Ptr CULong -> IO b) -> IO b
withSizeArray = withArray . liftM fromIntegral

put_var1 :: NcStorable a => Int -> Int -> [Int] -> a -> IO Int
put_var1 nc var idxs v = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
  alloca $ \iv -> do
    poke iv v
    withSizeArray idxs $ \idxsp -> do
      res <- ffi_put_var1 ncid varid idxsp iv
      return $ fromIntegral res

get_var1 :: NcStorable a => Int -> Int -> [Int] -> IO (Int, a)
get_var1 nc var idxs = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
  alloca $ \iv -> do
    withSizeArray idxs $ \idxsp -> do
      res <- ffi_get_var1 ncid varid idxsp iv
      v <- peek iv
      return $ (fromIntegral res, v)

put_var :: (NcStorable a, NcStore s) => Int -> Int -> s a -> IO Int
put_var nc var v = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
      is = toForeignPtr v
  withForeignPtr is $ \isp -> fromIntegral <$> ffi_put_var ncid varid isp

get_var :: (NcStorable a, NcStore s) => Int -> Int -> [Int] -> IO (Int, s a)
get_var nc var sz = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
  is <- mallocForeignPtrArray (product sz)
  withForeignPtr is $ \isp -> do
    res <- ffi_get_var ncid varid isp
    return (fromIntegral res, fromForeignPtr is sz)

put_vara :: (NcStorable a, NcStore s) =>
            Int -> Int -> [Int] -> [Int] -> s a -> IO Int
put_vara nc var start count v = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
      is = toForeignPtr v
  withForeignPtr is $ \isp ->
    withSizeArray start $ \startp ->
      withSizeArray count $ \countp -> do
        res <- ffi_put_vara ncid varid startp countp isp
        return $ fromIntegral res

get_vara :: (NcStorable a, NcStore s)
         => Int -> Int -> [Int] -> [Int] -> IO (Int, s a)
get_vara nc var start count = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
  is <- mallocForeignPtrArray (product count)
  withForeignPtr is $ \isp ->
    withSizeArray start $ \s ->
      withSizeArray count $ \c -> do
        res <- ffi_get_vara ncid varid s c isp
        return (fromIntegral res, fromForeignPtr is (filter (>1) count))

put_vars :: (NcStorable a, NcStore s) =>
            Int -> Int -> [Int] -> [Int] -> [Int] -> s a -> IO Int
put_vars nc var start count stride v = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
      is = toForeignPtr v
  withForeignPtr is $ \isp ->
    withSizeArray start $ \startp ->
      withSizeArray count $ \countp -> do
        withSizeArray stride $ \stridep -> do
          res <- ffi_put_vars ncid varid startp countp stridep isp
          return $ fromIntegral res

get_vars :: (NcStorable a, NcStore s)
         => Int -> Int -> [Int] -> [Int] -> [Int] -> IO (Int, s a)
get_vars nc var start count stride = do
  let ncid = fromIntegral nc
      varid = fromIntegral var
  is <- mallocForeignPtrArray (product count)
  withForeignPtr is $ \isp ->
    withSizeArray start $ \s ->
      withSizeArray count $ \c -> do
        withSizeArray stride $ \str -> do
          res <- ffi_get_vars ncid varid s c str isp
          return (fromIntegral res, fromForeignPtr is (filter (>1) count))


class Storable a => NcStorable a where
--  ncType :: a -> NcType
--  ncTypeVal :: a -> Int
--  type NcHsType a :: *
  ffi_put_var1 :: CInt -> CInt -> Ptr CULong -> Ptr a -> IO CInt
  ffi_get_var1 :: CInt -> CInt -> Ptr CULong -> Ptr a -> IO CInt
  ffi_put_var :: CInt -> CInt -> Ptr a -> IO CInt
  ffi_get_var :: CInt -> CInt -> Ptr a -> IO CInt
  ffi_put_vara :: CInt -> CInt -> Ptr CULong -> Ptr CULong -> Ptr a -> IO CInt
  ffi_get_vara :: CInt -> CInt -> Ptr CULong -> Ptr CULong -> Ptr a -> IO CInt
  ffi_put_vars :: CInt -> CInt -> Ptr CULong -> Ptr CULong -> Ptr CULong
               -> Ptr a -> IO CInt
  ffi_get_vars :: CInt -> CInt -> Ptr CULong -> Ptr CULong -> Ptr CULong
               -> Ptr a -> IO CInt


instance NcStorable CSChar where
  -- #define NC_BYTE 1 /**< signed 1 byte integer */
--  ncType _ = NcByte
--  ncTypeVal _ = 1
  ffi_put_var1 = nc_put_var1_schar'_
  ffi_get_var1 = nc_get_var1_schar'_
  ffi_put_var = nc_put_var_schar'_
  ffi_get_var = nc_get_var_schar'_
  ffi_put_vara = nc_put_vara_schar'_
  ffi_get_vara = nc_get_vara_schar'_
  ffi_put_vars = nc_put_vars_schar'_
  ffi_get_vars = nc_get_vars_schar'_

instance NcStorable CChar where
  -- #define NC_CHAR 2 /**< ISO/ASCII character */
--  ncType _ = NcChar
--  ncTypeVal _ = 2
  ffi_put_var1 = nc_put_var1_text'_
  ffi_get_var1 = nc_get_var1_text'_
  ffi_put_var = nc_put_var_text'_
  ffi_get_var = nc_get_var_text'_
  ffi_put_vara = nc_put_vara_text'_
  ffi_get_vara = nc_get_vara_text'_
  ffi_put_vars = nc_put_vars_text'_
  ffi_get_vars = nc_get_vars_text'_

instance NcStorable CShort where
  -- #define NC_SHORT 3 /**< signed 2 byte integer */
--  ncType _ = NcShort
--  ncTypeVal _ = 3
  ffi_put_var1 = nc_put_var1_short'_
  ffi_get_var1 = nc_get_var1_short'_
  ffi_put_var = nc_put_var_short'_
  ffi_get_var = nc_get_var_short'_
  ffi_put_vara = nc_put_vara_short'_
  ffi_get_vara = nc_get_vara_short'_
  ffi_put_vars = nc_put_vars_short'_
  ffi_get_vars = nc_get_vars_short'_

instance NcStorable CInt where
  -- #define NC_INT 4 /**< signed 4 byte integer */
--  ncType _ = NcInt
--  ncTypeVal _ = 4
  ffi_put_var1 = nc_put_var1_int'_
  ffi_get_var1 = nc_get_var1_int'_
  ffi_put_var = nc_put_var_int'_
  ffi_get_var = nc_get_var_int'_
  ffi_put_vara = nc_put_vara_int'_
  ffi_get_vara = nc_get_vara_int'_
  ffi_put_vars = nc_put_vars_int'_
  ffi_get_vars = nc_get_vars_int'_

instance NcStorable CFloat where
  -- #define NC_FLOAT 5 /**< single precision floating point number */
--  ncType _ = NcFloat
--  ncTypeVal _ = 5
  ffi_put_var1 = nc_put_var1_float'_
  ffi_get_var1 = nc_get_var1_float'_
  ffi_put_var = nc_put_var_float'_
  ffi_get_var = nc_get_var_float'_
  ffi_put_vara = nc_put_vara_float'_
  ffi_get_vara = nc_get_vara_float'_
  ffi_put_vars = nc_put_vars_float'_
  ffi_get_vars = nc_get_vars_float'_

instance NcStorable CDouble where
  -- #define NC_DOUBLE 6 /**< double precision floating point number */
--  ncType _ = NcDouble
--  ncTypeVal _ = 6
  ffi_put_var1 = nc_put_var1_double'_
  ffi_get_var1 = nc_get_var1_double'_
  ffi_put_var = nc_put_var_double'_
  ffi_get_var = nc_get_var_double'_
  ffi_put_vara = nc_put_vara_double'_
  ffi_get_vara = nc_get_vara_double'_
  ffi_put_vars = nc_put_vars_double'_
  ffi_get_vars = nc_get_vars_double'_

instance NcStorable CUChar where
  -- #define NC_UBYTE 7 /**< unsigned 1 byte int */
--  ncType _ = NcUByte
--  ncTypeVal _ = 7
  ffi_put_var1 = nc_put_var1_uchar'_
  ffi_get_var1 = nc_get_var1_uchar'_
  ffi_put_var = nc_put_var_uchar'_
  ffi_get_var = nc_get_var_uchar'_
  ffi_put_vara = nc_put_vara_uchar'_
  ffi_get_vara = nc_get_vara_uchar'_
  ffi_put_vars = nc_put_vars_uchar'_
  ffi_get_vars = nc_get_vars_uchar'_

instance NcStorable CUShort where
  -- #define NC_USHORT 8 /**< unsigned 2-byte int */
--  ncType _ = NcUShort
--  ncTypeVal _ = 8
  ffi_put_var1 = nc_put_var1_ushort'_
  ffi_get_var1 = nc_get_var1_ushort'_
  ffi_put_var = nc_put_var_ushort'_
  ffi_get_var = nc_get_var_ushort'_
  ffi_put_vara = nc_put_vara_ushort'_
  ffi_get_vara = nc_get_vara_ushort'_
  ffi_put_vars = nc_put_vars_ushort'_
  ffi_get_vars = nc_get_vars_ushort'_

instance NcStorable CUInt where
  -- #define NC_UINT 9 /**< unsigned 4-byte int */
--  ncType _ = NcUInt
--  ncTypeVal _ = 9
  ffi_put_var1 = nc_put_var1_uint'_
  ffi_get_var1 = nc_get_var1_uint'_
  ffi_put_var = nc_put_var_uint'_
  ffi_get_var = nc_get_var_uint'_
  ffi_put_vara = nc_put_vara_uint'_
  ffi_get_vara = nc_get_vara_uint'_
  ffi_put_vars = nc_put_vars_uint'_
  ffi_get_vars = nc_get_vars_uint'_

instance NcStorable CLong where
  -- #define NC_INT64 10 /**< signed 8-byte int */
--  ncType _ = NcInt64
--  ncTypeVal _ = 10
  ffi_put_var1 = nc_put_var1_long'_
  ffi_get_var1 = nc_get_var1_long'_
  ffi_put_var = nc_put_var_long'_
  ffi_get_var = nc_get_var_long'_
  ffi_put_vara = nc_put_vara_long'_
  ffi_get_vara = nc_get_vara_long'_
  ffi_put_vars = nc_put_vars_long'_
  ffi_get_vars = nc_get_vars_long'_

