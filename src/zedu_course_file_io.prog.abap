REPORT zedu_course_file_io.

*-----------------------------------------------------------------------
* Types
*-----------------------------------------------------------------------
TYPES: BEGIN OF ty_course_csv,
         course_id    TYPE zedu_course-course_id,
         course_name  TYPE zedu_course-course_name,
         course_type  TYPE zedu_course-course_type,
         start_date   TYPE zedu_course-start_date,
         end_date     TYPE zedu_course-end_date,
         created_by   TYPE zedu_course-created_by,
         created_date TYPE zedu_course-created_date,
       END OF ty_course_csv.

*-----------------------------------------------------------------------
* Data
*-----------------------------------------------------------------------
DATA: gt_file       TYPE STANDARD TABLE OF string,
      gt_course_csv TYPE STANDARD TABLE OF ty_course_csv,
      gt_course     TYPE STANDARD TABLE OF zedu_course.

DATA: gv_file_id            TYPE zedu_file_hdr-file_id,
      gv_original_file_name TYPE zedu_file_hdr-original_file_name,
      gv_physical_file_name TYPE zedu_file_hdr-physical_file_name,
      gv_physical_full_path TYPE zedu_file_hdr-physical_full_path,
      gv_total_count        TYPE i,
      gv_success_count      TYPE i,
      gv_error_count        TYPE i,
      gv_server_saved       TYPE abap_bool.

*-----------------------------------------------------------------------
* Selection Screen
*-----------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

PARAMETERS: p_up   RADIOBUTTON GROUP rg1 DEFAULT 'X',
            p_down RADIOBUTTON GROUP rg1.

PARAMETERS: p_file   TYPE string LOWER CASE,
            p_srvdir TYPE string LOWER CASE DEFAULT '/usr/sap/tmp/',
            p_save   AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b1.


*-----------------------------------------------------------------------
* File Dialog
*-----------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  IF p_up = abap_true.
    PERFORM select_upload_file.
  ELSE.
    PERFORM select_download_file.
  ENDIF.

*-----------------------------------------------------------------------
* Start
*-----------------------------------------------------------------------
START-OF-SELECTION.

  IF p_file IS INITIAL.
    MESSAGE '파일 경로를 입력하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF p_up = abap_true.
    PERFORM process_upload.
  ELSE.
    PERFORM process_download.
  ENDIF.

*-----------------------------------------------------------------------
* Upload Main
*-----------------------------------------------------------------------
FORM process_upload.

  PERFORM make_file_info USING 'COURSE_UPLOAD'.
  PERFORM upload_frontend_file.
  PERFORM convert_csv_to_course.
  PERFORM insert_course_data.

  IF p_save = abap_true.
    PERFORM save_file_to_server.
  ENDIF.

  PERFORM save_file_header USING 'COURSE_UPLOAD'.

  WRITE: / 'Upload completed.'.
  WRITE: / 'File ID       :', gv_file_id.
  WRITE: / 'Original File :', gv_original_file_name.
  WRITE: / 'Physical File :', gv_physical_file_name.
  WRITE: / 'Total Count   :', gv_total_count.
  WRITE: / 'Success Count :', gv_success_count.
  WRITE: / 'Error Count   :', gv_error_count.
  WRITE: / 'Server Path   :', gv_physical_full_path.

ENDFORM.

*-----------------------------------------------------------------------
* Download Main
*-----------------------------------------------------------------------
FORM process_download.

  PERFORM make_file_info USING 'COURSE_DOWNLOAD'.
  PERFORM select_course_data.
  PERFORM convert_course_to_csv.
  PERFORM download_frontend_file.

  IF p_save = abap_true.
    PERFORM save_file_to_server.
  ENDIF.

  PERFORM save_file_header USING 'COURSE_DOWNLOAD'.

  WRITE: / 'Download completed.'.
  WRITE: / 'File ID       :', gv_file_id.
  WRITE: / 'Local File    :', p_file.
  WRITE: / 'Physical File :', gv_physical_file_name.
  WRITE: / 'Total Count   :', gv_total_count.
  WRITE: / 'Server Path   :', gv_physical_full_path.

ENDFORM.

*-----------------------------------------------------------------------
* Select Upload File
*-----------------------------------------------------------------------
FORM select_upload_file.

  DATA: lt_filetable TYPE filetable,
        lv_rc        TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title = 'CSV 파일 선택'
    CHANGING
      file_table   = lt_filetable
      rc           = lv_rc
  ).

  IF lv_rc > 0.
    READ TABLE lt_filetable INTO DATA(ls_file) INDEX 1.
    IF sy-subrc = 0.
      p_file = ls_file-filename.
    ENDIF.
  ENDIF.

ENDFORM.

*-----------------------------------------------------------------------
* Select Download File
*-----------------------------------------------------------------------
FORM select_download_file.

  DATA: lv_filename TYPE string,
        lv_path     TYPE string,
        lv_fullpath TYPE string,
        lv_action   TYPE i.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      window_title      = 'CSV 저장 경로 선택'
      default_extension = 'csv'
      default_file_name = 'zedu_course_download.csv'
    CHANGING
      filename          = lv_filename
      path              = lv_path
      fullpath          = lv_fullpath
      user_action       = lv_action
  ).

  IF lv_action = cl_gui_frontend_services=>action_ok.
    p_file = lv_fullpath.
  ENDIF.

ENDFORM.

*-----------------------------------------------------------------------
* Make File Info
*-----------------------------------------------------------------------
FORM make_file_info USING pv_process_type TYPE char20.

  DATA lv_dir TYPE string.

  CLEAR: gv_file_id,
         gv_original_file_name,
         gv_physical_file_name,
         gv_physical_full_path,
         gv_total_count,
         gv_success_count,
         gv_error_count,
         gv_server_saved.

  CONCATENATE 'FILE'
              sy-datum
              sy-uzeit
    INTO gv_file_id.

  gv_original_file_name = p_file.

  PERFORM get_file_name_from_path
    USING p_file
    CHANGING gv_original_file_name.

  CONCATENATE 'ZEDU_COURSE_'
              sy-datum
              '_'
              sy-uzeit
              '_'
              sy-uname
              '.csv'
    INTO gv_physical_file_name.

  lv_dir = p_srvdir.

  IF lv_dir IS INITIAL.
    lv_dir = '/usr/sap/tmp/'.
  ENDIF.

  IF lv_dir CP '*/'.
    CONCATENATE lv_dir gv_physical_file_name INTO gv_physical_full_path.
  ELSE.
    CONCATENATE lv_dir '/' gv_physical_file_name INTO gv_physical_full_path.
  ENDIF.

ENDFORM.

*-----------------------------------------------------------------------
* Get File Name From Full Path
*-----------------------------------------------------------------------
FORM get_file_name_from_path
  USING    pv_fullpath TYPE string
  CHANGING pv_filename TYPE zedu_file_hdr-original_file_name.

  DATA: lv_path TYPE string,
        lt_part TYPE STANDARD TABLE OF string,
        lv_idx  TYPE i,
        lv_name TYPE string.

  lv_path = pv_fullpath.

  REPLACE ALL OCCURRENCES OF '\' IN lv_path WITH '/'.

  SPLIT lv_path AT '/' INTO TABLE lt_part.

  lv_idx = lines( lt_part ).

  READ TABLE lt_part INTO lv_name INDEX lv_idx.
  IF sy-subrc = 0.
    pv_filename = lv_name.
  ENDIF.

ENDFORM.

*-----------------------------------------------------------------------
* Upload Local File
*-----------------------------------------------------------------------
FORM upload_frontend_file.

  CLEAR gt_file.

  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename = p_file
      filetype = 'ASC'
    CHANGING
      data_tab = gt_file
  ).

ENDFORM.

*-----------------------------------------------------------------------
* Convert CSV To Course
*-----------------------------------------------------------------------
FORM convert_csv_to_course.

  DATA: lv_line TYPE string,
        ls_csv  TYPE ty_course_csv.

  CLEAR gt_course_csv.

  LOOP AT gt_file INTO lv_line.

    "Header skip
    IF sy-tabix = 1.
      CONTINUE.
    ENDIF.

    IF lv_line IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR ls_csv.

    SPLIT lv_line AT ','
      INTO ls_csv-course_id
           ls_csv-course_name
           ls_csv-course_type
           ls_csv-start_date
           ls_csv-end_date
           ls_csv-created_by
           ls_csv-created_date.

    IF ls_csv-course_id IS INITIAL.
      CONTINUE.
    ENDIF.

    APPEND ls_csv TO gt_course_csv.

  ENDLOOP.

  gv_total_count = lines( gt_course_csv ).

ENDFORM.

*-----------------------------------------------------------------------
* Insert Course Data
*-----------------------------------------------------------------------
FORM insert_course_data.

  DATA ls_course TYPE zedu_course.

  CLEAR gt_course.

  LOOP AT gt_course_csv INTO DATA(ls_csv).

    CLEAR ls_course.

    ls_course-mandt        = sy-mandt.
    ls_course-course_id    = ls_csv-course_id.
    ls_course-course_name  = ls_csv-course_name.
    ls_course-course_type  = ls_csv-course_type.
    ls_course-start_date   = ls_csv-start_date.
    ls_course-end_date     = ls_csv-end_date.
    ls_course-created_by   = ls_csv-created_by.
    ls_course-created_date = ls_csv-created_date.

    APPEND ls_course TO gt_course.

  ENDLOOP.

  IF gt_course IS INITIAL.
    MESSAGE 'INSERT 대상 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  INSERT zedu_course FROM TABLE gt_course ACCEPTING DUPLICATE KEYS.

  gv_success_count = sy-dbcnt.
  gv_error_count   = gv_total_count - gv_success_count.

  COMMIT WORK AND WAIT.

ENDFORM.

*-----------------------------------------------------------------------
* Select Course Data For Download
*-----------------------------------------------------------------------
FORM select_course_data.

  CLEAR gt_course.

  SELECT *
    FROM zedu_course
    INTO TABLE @gt_course
    ORDER BY course_id.

  gv_total_count   = lines( gt_course ).
  gv_success_count = gv_total_count.
  gv_error_count   = 0.

ENDFORM.

*-----------------------------------------------------------------------
* Convert Course To CSV
*-----------------------------------------------------------------------
FORM convert_course_to_csv.

  DATA lv_line TYPE string.

  CLEAR gt_file.

  APPEND 'COURSE_ID,COURSE_NAME,COURSE_TYPE,START_DATE,END_DATE,CREATED_BY,CREATED_DATE'
    TO gt_file.

  LOOP AT gt_course INTO DATA(ls_course).

    CLEAR lv_line.

    CONCATENATE ls_course-course_id
                ls_course-course_name
                ls_course-course_type
                ls_course-start_date
                ls_course-end_date
                ls_course-created_by
                ls_course-created_date
      INTO lv_line SEPARATED BY ','.

    APPEND lv_line TO gt_file.

  ENDLOOP.

ENDFORM.

*-----------------------------------------------------------------------
* Download Local File
*-----------------------------------------------------------------------
FORM download_frontend_file.

  IF gt_file IS INITIAL.
    MESSAGE '다운로드할 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>gui_download(
    EXPORTING
      filename = p_file
      filetype = 'ASC'
    CHANGING
      data_tab = gt_file
  ).

ENDFORM.

*-----------------------------------------------------------------------
* Save File To Application Server
*-----------------------------------------------------------------------
FORM save_file_to_server.

  DATA lv_line TYPE string.

  gv_server_saved = abap_false.

  IF gt_file IS INITIAL.
    RETURN.
  ENDIF.

  OPEN DATASET gv_physical_full_path
    FOR OUTPUT IN TEXT MODE ENCODING UTF-8.

  IF sy-subrc <> 0.
    MESSAGE 'Application Server 파일 저장 실패. AL11 경로를 확인하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_file INTO lv_line.
    TRANSFER lv_line TO gv_physical_full_path.
  ENDLOOP.

  CLOSE DATASET gv_physical_full_path.

  gv_server_saved = abap_true.

ENDFORM.

*-----------------------------------------------------------------------
* Save File Header
*-----------------------------------------------------------------------
FORM save_file_header USING pv_process_type TYPE char20.

  DATA ls_file_hdr TYPE zedu_file_hdr.

  CLEAR ls_file_hdr.

  ls_file_hdr-mandt              = sy-mandt.
  ls_file_hdr-file_id            = gv_file_id.
  ls_file_hdr-process_type       = pv_process_type.
  ls_file_hdr-logical_path       = 'ZEDU_UPLOAD_PATH'.
  ls_file_hdr-logical_file       = 'ZEDU_COURSE_FILE'.
  ls_file_hdr-original_file_name = gv_original_file_name.
  ls_file_hdr-physical_file_name = gv_physical_file_name.
  ls_file_hdr-physical_full_path = gv_physical_full_path.
  ls_file_hdr-file_ext           = 'CSV'.
  ls_file_hdr-file_size          = 0.
  ls_file_hdr-total_count        = gv_total_count.
  ls_file_hdr-success_count      = gv_success_count.
  ls_file_hdr-error_count        = gv_error_count.

  IF gv_error_count > 0.
    ls_file_hdr-status = 'E'.
  ELSE.
    ls_file_hdr-status = 'S'.
  ENDIF.

  ls_file_hdr-created_by         = sy-uname.
  ls_file_hdr-created_date       = sy-datum.
  ls_file_hdr-created_time       = sy-uzeit.

  INSERT zedu_file_hdr FROM ls_file_hdr.

  COMMIT WORK AND WAIT.

ENDFORM.
