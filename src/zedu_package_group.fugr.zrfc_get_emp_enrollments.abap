FUNCTION zrfc_get_emp_enrollments.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_EMP_ID) TYPE  ZEDU_ENROLL-EMP_ID
*"  TABLES
*"      ET_RESULT TYPE  ZEDU_EMP_ENROLL_TT
*"----------------------------------------------------------------------

  CLEAR et_result[].

  SELECT enroll_id,
         course_id,
         emp_id,
         emp_name,
         dept_name,
         status,
         req_date,
         comp_date
    FROM zedu_enroll
    WHERE emp_id = @iv_emp_id
    INTO CORRESPONDING FIELDS OF TABLE @et_result.

ENDFUNCTION.
