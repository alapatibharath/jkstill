

-- fktree-rcte.sql
-- Create a tree of tables based on FK relations
-- This is the RCTE (Recursive Common Table Expression) version
-- Jared Still - Pythian 2020-11-04
-- jkstill@gmail.com still@pythian.com


/*

The RCTE (Recursive Common Table Expression) version is encountering a bug in Oracle 19.8

Bug 30877518 - ORA-600[qctcte1] From SQL Statement With A With-clause (Doc ID 30877518.8)

====

SYS@ora192rac-scan/pdb4.jks.com AS SYSDBA> @fktc
from fk_tree d
*
ERROR at line 43:
ORA-00600: internal error code, arguments: [qctcte1], [0], [], [], [], [], [], [], [], [], [], []

*/

@clears

col parent format a30
col child format a30
col table_name format a30
col parent_pk_name format a30
col constraint_name format a30
col r_constraint_name format a30

col constraint_type format a30
col child format a30
col child_fk_name format a30
col r_parent_pk_name format a30

set linesize 200 trimspool on
set pagesize 100

col v_user new_value v_user noprint

prompt Schema for FK Tree? :

set term off feed off
select upper('&1') v_user from dual;
set term on feed on

with fk_tree (
	table_name
	, constraint_name
	, constraint_type
	, r_constraint_name
	, delete_rule
	, lvl
	, idx
) as (
	select
		c.table_name
		, c.constraint_name
		, c.constraint_type
		, c.r_constraint_name
		, c.delete_rule
		, 1 as lvl
		, rownum - 1 as idx
	from all_constraints c
	where c.owner = '&v_user'
		and c.constraint_type in ('U','P')
	union all
	select
		c.table_name
		, c.constraint_name
		, c.constraint_type
		, c.r_constraint_name
		, c.delete_rule
		, fkt.lvl+1 as lvl
		, fkt.idx+1 as idx
	from all_constraints c
	join fk_tree fkt on
		c.r_constraint_name = fkt.constraint_name
	where c.owner = '&v_user'
		and c.constraint_type in ('R')
)
search depth first by table_name set order1
select
	lpad(' ',(lvl-1)*2) || d.table_name table_name
	, r_constraint_name
	, constraint_name
	, delete_rule
	--, level
from fk_tree d
connect by nocycle prior constraint_name = r_constraint_name
start with constraint_type in ('P','U')
/

undef 1

