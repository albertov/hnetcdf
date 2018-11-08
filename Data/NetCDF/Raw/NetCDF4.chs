{-# LANGUAGE ForeignFunctionInterface #-}

-- | Raw bindings for NetCDF4 features (not implemented).

module Data.NetCDF.Raw.NetCDF4 where

import Data.NetCDF.Raw.Utils

#include <netcdf.h>

--------------------------------------------------------------------------------
--
--  UNSUPPORTED FEATURES (NetCDF-4)
--
--------------------------------------------------------------------------------

-- USER DEFINED TYPES
--
-- int nc_def_compound(int ncid, size_t size,
--                     const char *name, nc_type *typeidp);
-- int nc_insert_compound(int ncid, nc_type xtype, const char *name,
--                        size_t offset, nc_type field_typeid);
-- int nc_insert_array_compound(int ncid, nc_type xtype, const char *name,
--                              size_t offset, nc_type field_typeid,
--                              int ndims, const int *dim_sizes);
-- int nc_inq_type(int ncid, nc_type xtype, char *name, size_t *size);
-- int nc_inq_compound(int ncid, nc_type xtype, char *name, size_t *sizep,
--                     size_t *nfieldsp);
-- int nc_inq_compound_name(int ncid, nc_type xtype, char *name);
-- int nc_inq_compound_size(int ncid, nc_type xtype, size_t *sizep);
-- int nc_inq_compound_nfields(int ncid, nc_type xtype, size_t *nfieldsp);
-- int nc_inq_compound_fieldname(int ncid, nc_type xtype, int fieldid,
--                               char *name);
-- int nc_inq_compound_fieldindex(int ncid, nc_type xtype, const char *name,
--                                int *fieldidp);
-- int nc_inq_compound_fieldoffset(int ncid, nc_type xtype, int fieldid,
--                                 size_t *offsetp);
-- int nc_inq_compound_fieldtype(int ncid, nc_type xtype, int fieldid,
--                               nc_type *field_typeidp);
-- int nc_inq_compound_fieldndims(int ncid, nc_type xtype, int fieldid,
--                                int *ndimsp);
-- int nc_inq_compound_fielddim_sizes(int ncid, nc_type xtype, int fieldid,
--                                    int *dim_sizes);
-- typedef struct {
--     size_t len; /**< Length of VL data (in base type units) */
--     void *p;    /**< Pointer to VL data */
-- } nc_vlen_t;
-- int nc_def_vlen(int ncid, const char *name,
--                 nc_type base_typeid, nc_type *xtypep);
-- int nc_inq_vlen(int ncid, nc_type xtype, char *name, size_t *datum_sizep,
--                 nc_type *base_nc_typep);
-- int nc_free_vlen(nc_vlen_t *vl);
-- int nc_put_vlen_element(int ncid, int typeid1, void *vlen_element,
--                         size_t len, const void *data);
-- int nc_get_vlen_element(int ncid, int typeid1, const void *vlen_element,
--                         size_t *len, void *data);
-- int nc_free_string(size_t len, char **data);
-- int nc_inq_user_type(int ncid, nc_type xtype, char *name, size_t *size,
--                      nc_type *base_nc_typep, size_t *nfieldsp, int *classp);
-- int nc_def_enum(int ncid, nc_type base_typeid, const char *name,
--                 nc_type *typeidp);
-- int nc_insert_enum(int ncid, nc_type xtype, const char *name,
--                    const void *value);
-- int nc_inq_enum_member(int ncid, nc_type xtype, int idx, char *name,
--                        void *value);
-- int nc_inq_enum_ident(int ncid, nc_type xtype, long long value,
--                       char *identifier);
-- int nc_def_opaque(int ncid, size_t size, const char *name, nc_type *xtypep);
-- int nc_inq_opaque(int ncid, nc_type xtype, char *name, size_t *sizep);
-- int nc_inq_typeid(int ncid, const char *name, nc_type *typeidp);
-- int nc_inq_compound_field(int ncid, nc_type xtype, int fieldid, char *name,
--                           size_t *offsetp, nc_type *field_typeidp,
--                           int *ndimsp, int *dim_sizesp);
-- int nc_free_vlens(size_t len, nc_vlen_t vlens[]);
-- int nc_inq_enum(int ncid, nc_type xtype, char *name, nc_type *base_nc_typep,
--                 size_t *base_sizep, size_t *num_membersp);

-- GROUPS
--
-- int nc_inq_ncid(int ncid, const char *name, int *grp_ncid);
-- int nc_inq_grps(int ncid, int *numgrps, int *ncids);
-- int nc_inq_grpname(int ncid, char *name);
-- int nc_inq_grpname_full(int ncid, size_t *lenp, char *full_name);
-- int nc_inq_grpname_len(int ncid, size_t *lenp);
-- int nc_inq_grp_parent(int ncid, int *parent_ncid);
-- int nc_inq_grp_ncid(int ncid, const char *grp_name, int *grp_ncid);
-- int nc_inq_grp_full_ncid(int ncid, const char *full_name, int *grp_ncid);
-- int nc_inq_varids(int ncid, int *nvars, int *varids);
-- int nc_inq_dimids(int ncid, int *ndims, int *dimids, int include_parents);
-- int nc_inq_typeids(int ncid, int *ntypes, int *typeids);
-- int nc_def_grp(int parent_ncid, const char *name, int *new_ncid);

-- NETCDF-4 VARIABLES
--
-- int nc_def_var_deflate(int ncid, int varid, int shuffle, int deflate,
--                        int deflate_level);
{#fun nc_def_var_deflate { `Int', `Int', `Int', `Int', `Int'} -> `Int' #}
-- int nc_inq_var_deflate(int ncid, int varid, int *shufflep,
--                        int *deflatep, int *deflate_levelp);

{#fun nc_inq_var_deflate { `Int', `Int', alloca- `Int' peekIntConv*, alloca-
`Int' peekIntConv*, alloca- `Int' peekIntConv*} -> `Int' #}
-- int nc_def_var_fletcher32(int ncid, int varid, int fletcher32);
-- int nc_inq_var_fletcher32(int ncid, int varid, int *fletcher32p);
-- int nc_def_var_chunking(int ncid, int varid, int storage,
--                         const size_t *chunksizesp);
-- int nc_inq_var_chunking(int ncid, int varid, int *storagep,
--                         size_t *chunksizesp);
-- int nc_def_var_fill(int ncid, int varid, int no_fill,
--                     const void *fill_value);
-- int nc_inq_var_fill(int ncid, int varid, int *no_fill, void *fill_valuep);
-- int nc_def_var_endian(int ncid, int varid, int endian);
-- int nc_inq_var_endian(int ncid, int varid, int *endianp);
-- int nc_set_chunk_cache(size_t size, size_t nelems, float preemption);
-- int nc_get_chunk_cache(size_t *sizep, size_t *nelemsp, float *preemptionp);
-- int nc_set_var_chunk_cache(int ncid, int varid, size_t size, size_t nelems,
--                            float preemption);
-- int nc_get_var_chunk_cache(int ncid, int varid, size_t *sizep,
--                            size_t *nelemsp, float *preemptionp);
-- int nc_inq_var_szip(int ncid, int varid, int *options_maskp,
--                     int *pixels_per_blockp);

-- Variable length strings are only supported in NetCDF-4 files, which
-- we don't handle yet.
--
-- int nc_put_var_string(int ncid, int varid, const char **op);
-- int nc_get_var_string(int ncid, int varid, char **ip);
-- int nc_put_var1_string(int ncid, int varid, const size_t *indexp,
--                        const char **op);
-- int nc_get_var1_string(int ncid, int varid, const size_t *indexp,
--                        char **ip);
-- int nc_put_vara_string(int ncid, int varid, const size_t *startp,
--                        const size_t *countp, const char **op);
-- int nc_get_vara_string(int ncid, int varid, const size_t *startp,
--                        const size_t *countp, char **ip);
-- int nc_put_vars_string(int ncid, int varid, const size_t *startp,
--                        const size_t *countp, const ptrdiff_t *stridep,
--                        const char **op);
-- int nc_get_vars_string(int ncid, int varid, const size_t *startp,
--                        const size_t *countp, const ptrdiff_t *stridep,
--                        char **ip);
-- int nc_put_varm_string(int ncid, int varid, const size_t *startp,
--                        const size_t *countp, const ptrdiff_t *stridep,
--                        const ptrdiff_t * imapp, const char **op);
-- int nc_get_varm_string(int ncid, int varid, const size_t *startp,
--                        const size_t *countp, const ptrdiff_t *stridep,
--                        const ptrdiff_t * imapp, char **ip);
-- int nc_put_att_string(int ncid, int varid, const char *name,
--                       size_t len, const char **op);
-- int nc_get_att_string(int ncid, int varid, const char *name, char **ip);

-- MISCELLANEOUS
--
-- int nc_var_par_access(int ncid, int varid, int par_access);
-- int nc_inq_type_equal(int ncid1, nc_type typeid1, int ncid2,
--                       nc_type typeid2, int *equal);
-- int nc_set_default_format(int format, int *old_formatp);
