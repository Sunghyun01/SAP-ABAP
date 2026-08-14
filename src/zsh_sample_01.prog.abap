REPORT zsh_sample_01.

TYPE-POOLS: slis.

TYPES: BEGIN OF ty_order,
         order_id TYPE i,
         customer TYPE char20,
         amount   TYPE i,
         status   TYPE char10,
       END OF ty_order.

DATA: gt_order TYPE STANDARD TABLE OF ty_order,
      gs_order TYPE ty_order,          " ← SELECT-OPTIONS 참조용 work area 추가
      gt_fcat  TYPE slis_t_fieldcat_alv,
      gs_fcat  TYPE slis_fieldcat_alv.

SELECT-OPTIONS: s_ordid FOR gs_order-order_id.   " ← gt_order 대신 gs_order 사용

START-OF-SELECTION.

  gt_order = VALUE #(
    ( order_id = 10001 customer = 'Samsung' amount = 120000 status = '완료' )
    ( order_id = 10002 customer = 'LG'      amount =  85000 status = '진행중' )
    ( order_id = 10003 customer = 'Kakao'   amount =  45000 status = '대기' )
  ).

  IF s_ordid[] IS NOT INITIAL.
    DELETE gt_order WHERE order_id NOT IN s_ordid.
  ENDIF.

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
