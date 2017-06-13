#!/bin/sh -e

printf -- "--[[ This file is generated by ./kres-gen.sh ]] ffi.cdef[[\n"

## Various types (mainly), from libknot and libkres

printf "
typedef struct knot_dump_style knot_dump_style_t;
extern const knot_dump_style_t KNOT_DUMP_STYLE_DEFAULT;
"

# The generator doesn't work well with typedefs of functions.
printf "
typedef struct knot_mm {
	void *ctx, *alloc, *free;
} knot_mm_t;

typedef void *(*map_alloc_f)(void *, size_t);
typedef void (*map_free_f)(void *baton, void *ptr);
"

./scripts/gen-cdefs.sh libkres types <<-EOF
	knot_section_t
	knot_rrinfo_t
	knot_dname_t
	knot_rdata_t
	knot_rdataset_t
	struct knot_rdataset
	knot_rrset_t
	knot_pktsection_t
	struct knot_pkt
	knot_pkt_t
	# generics
	map_t
	# libkres
	rr_array_t
	struct ranked_rr_array_entry
	ranked_rr_array_entry_t
	ranked_rr_array_t
	struct kr_zonecut
	kr_qarray_t
	struct kr_rplan
	struct kr_request
EOF

genResType() {
	echo "$1" | ./scripts/gen-cdefs.sh libkres types
}

# No simple way to fixup this rename in ./kres.lua AFAIK.
genResType "struct knot_rrset" | sed 's/\<owner\>/_owner/'

## Some definitions would need too many deps, so shorten them.

genResType "struct kr_nsrep" | sed '/union/,$ d'
printf "\t/* beware: hidden stub */\n};\n"

genResType "struct kr_query" | sed '/struct kr_layer_pickle/,$ d'
printf "\t/* ^hidden stub^ */\n\tchar _stub[];\n};\n"

genResType "struct kr_context" | sed '/struct kr_cache/,$ d'
printf "\tchar _stub[];\n};\n"

# Getting struct query_flag is a bit complex.
genResType "enum kr_query_flag" | sed -e 's/enum kr_query_flag/struct query_flag/' \
		-e 's/QUERY_NO_THROTTLE/& = 2/' `# a special case for consecutive integers` \
		-e 's@\<QUERY_\([A-Z_0-9]*\) = \([0-9]*\)@static const int \1 = \2;@g' \
		-e 's/,//g'

## libknot API
./scripts/gen-cdefs.sh libknot functions <<-EOF
# Domain names
	knot_dname_size
	knot_dname_from_str
	knot_dname_to_str
# Resource records
	knot_rdata_rdlen
	knot_rdata_data
	knot_rdataset_at
	knot_rrset_add_rdata
	knot_rrset_init_empty
	knot_rrset_ttl
	knot_rrset_txt_dump
	knot_rrset_txt_dump_data
# Packet
	knot_pkt_qname
	knot_pkt_qtype
	knot_pkt_qclass
	knot_pkt_begin
	knot_pkt_put_question
	knot_pkt_rr
	knot_pkt_section
EOF

## libkres API
./scripts/gen-cdefs.sh libkres functions <<-EOF
# Resolution request
	kr_resolve_plan
	kr_resolve_pool
# Resolution plan
	kr_rplan_push
	kr_rplan_pop
	kr_rplan_resolved
# Nameservers
	kr_nsrep_set
# Utils
	kr_rand_uint
	kr_pkt_make_auth_header
	kr_pkt_put
	kr_pkt_recycle
	kr_inaddr
	kr_inaddr_family
	kr_inaddr_len
	kr_straddr_family
	kr_straddr_subnet
	kr_bitcmp
	kr_family_len
	kr_straddr_socket
	kr_rrarray_add
	kr_ranked_rrarray_add
# Trust anchors
	kr_ta_get
	kr_ta_add
	kr_ta_del
	kr_ta_clear
# DNSSEC
	kr_dnssec_key_ksk
	kr_dnssec_key_revoked
	kr_dnssec_key_tag
	kr_dnssec_key_match
EOF

printf "]]\n"

exit 0
