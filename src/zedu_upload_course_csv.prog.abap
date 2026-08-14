*&---------------------------------------------------------------------*
*& Report zedu_upload_course_csv
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zedu_upload_course_csv.

TYPES: BEGIN OF ty_csv,
         course_id    TYPE zedu_course-course_id,
         course_name  TYPE zedu_course-course_name,
         course_type  TYPE zedu_course-course_type,
         start_date   TYPE zedu_course-start_date,
         end_date     TYPE zedu_course-end_date,
         created_by    TYPE zedu_course-created_by,
         created_date TYPE zedu_course-created_date,
       END OF ty_csv.

DATA:gt_csv    TYPE STANDARD TABLE OF ty_csv,
     gs_csv    TYPE ty_csv,
     gt_course TYPE STANDARD TABLE OF zedu_course,
     gs_course TYPE zedu_course.

DATA: gt_file TYPE STANDARD TABLE OF string,
      gv_file TYPE string.

PARAMETERS p_file TYPE string LOWER CASE.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  DATA: lt_filetable TYPE filetable,
        LV_rc        TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    CHANGING
      file_table              = lt_filetable
      rc                      = lv_rc
  ).

  IF lv_rc > 0.
    READ TABLE lt_filetable INTO DATA(ls_file) INDEX 1.
    IF sy-subrc = 0.
      p_file = ls_file-filename.
    ENDIF.
  ENDIF.

START-OF-SELECTION.

  PERFORM upload_csv.
  PERFORM convert_data.
  PERFORM insert_data.


FORM upload_csv.
  gv_file = p_file.

  cl_gui_frontend_services=>gui_upload(
  EXPORTING
      filename = gv_file
      filetype = 'ASC'
       has_field_separator = abap_false
    CHANGING
      data_tab                = gt_file
  ).
ENDFORM.

FORM convert_data.
  DATA: lv_line TYPE string.

  LOOP AT gt_file INTO lv_line.

    IF sy-tabix = 1.
      CONTINUE..
    ENDIF.

    CLEAR gs_csv.

    SPLIT lv_line AT ','
    INTO gs_csv-course_id
        gs_csv-course_name
        gs_csv-course_type
        gs_csv-start_date
        gs_csv-end_date
        gs_csv-created_by
        gs_csv-created_date.

    IF gs_csv-course_id IS INITIAL.
      CONTINUE.


    ENDIF.

    APPEND gs_csv TO gt_csv.
  ENDLOOP.
ENDFORM.

FORM insert_data.

  CLEAR gt_course.

  LOOP AT gt_csv INTO gs_csv.

    CLEAR gs_course.

    gs_course-mandt        = sy-mandt.
    gs_course-course_id    = gs_csv-course_id.
    gs_course-course_name  = gs_csv-course_name.
    gs_course-course_type  = gs_csv-course_type.
    gs_course-start_date   = gs_csv-start_date.
    gs_course-end_date     = gs_csv-end_date.
    gs_course-created_by   = gs_csv-created_by.
    gs_course-created_date = gs_csv-created_date.

    APPEND gs_course TO gt_course.

  ENDLOOP.

  IF gt_course IS INITIAL.
    MESSAGE '업로드할 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  INSERT zedu_course FROM TABLE gt_course ACCEPTING DUPLICATE KEYS.

  COMMIT WORK AND WAIT.

  WRITE: / 'CSV Read Count   :', lines( gt_csv ).
  WRITE: / 'Insert Try Count :', lines( gt_course ).
  WRITE: / 'Inserted Count   :', sy-dbcnt.
  WRITE: / 'Upload Completed.'.

ENDFORM.
