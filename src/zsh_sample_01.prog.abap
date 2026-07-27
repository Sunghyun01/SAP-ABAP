*&---------------------------------------------------------------------*
*& Report ZSH_SAMPLE_01
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZSH_SAMPLE_01.

TYPE-POOLS: slis.

TYPES: BEGIN OF ty_order,
         order_id TYPE i,
         customer TYPE char20,
         amount   TYPE i,
         status   TYPE char10,
       END OF ty_order.

DATA: gt_order TYPE STANDARD TABLE OF ty_order,
      gt_fcat  TYPE slis_t_fieldcat_alv,
      gs_fcat  TYPE slis_fieldcat_alv.

START-OF-SELECTION.

  gt_order = VALUE #(
    ( order_id = 10001 customer = 'Samsung' amount = 120000 status = '완료' )
    ( order_id = 10002 customer = 'LG'      amount =  85000 status = '진행중' )
    ( order_id = 10003 customer = 'Kakao'   amount =  45000 status = '대기' )
  ).

  PERFORM build_fieldcat.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      it_fieldcat        = gt_fcat
    TABLES
      t_outtab           = gt_order
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    WRITE: / 'ALV 출력 오류'.
  ENDIF.

FORM build_fieldcat.

  CLEAR gs_fcat.
  gs_fcat-fieldname = 'ORDER_ID'.
  gs_fcat-seltext_m = '주문번호'.
  APPEND gs_fcat TO gt_fcat.

  CLEAR gs_fcat.
  gs_fcat-fieldname = 'CUSTOMER'.
  gs_fcat-seltext_m = '고객'.
  APPEND gs_fcat TO gt_fcat.

  CLEAR gs_fcat.
  gs_fcat-fieldname = 'AMOUNT'.
  gs_fcat-seltext_m = '금액'.
  gs_fcat-do_sum    = 'X'.
  APPEND gs_fcat TO gt_fcat.

  CLEAR gs_fcat.
  gs_fcat-fieldname = 'STATUS'.
  gs_fcat-seltext_m = '상태'.
  APPEND gs_fcat TO gt_fcat.

ENDFORM.
