*&---------------------------------------------------------------------*
*& Report ZEDU_STATUS_UPDATE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zedu_status_update.

DATA: ls_enroll      TYPE zedu_enroll,
      lv_status_text TYPE char10.

PARAMETERS: p_enrid TYPE zedu_enroll-enroll_id OBLIGATORY,
            p_stat  TYPE zedu_enroll-status OBLIGATORY.

AT SELECTION-SCREEN.
  CASE p_stat.
    WHEN 'A' OR 'C' OR 'N' OR 'X'.
      " 정상 상태값
    WHEN OTHERS.
      MESSAGE '상태값은 A, C, N, X 중 하나만 입력 가능합니다.' TYPE 'E'.
  ENDCASE.

START-OF-SELECTION.

  PERFORM get_status_text.
  PERFORM update_status.

FORM get_status_text.

  lv_status_text = SWITCH char10( p_stat
  WHEN 'A' THEN '신청'
  WHEN 'C' THEN '이수'
  WHEN 'N' THEN '미이수'
  WHEN 'X' THEN '취소'
  ELSE '기타'
).

ENDFORM.

FORM update_status.

  CLEAR ls_enroll.

  SELECT SINGLE *
    FROM zedu_enroll
    INTO ls_enroll
    WHERE enroll_id = p_enrid.

  IF sy-subrc <> 0.
    MESSAGE '존재하지 않는 신청 ID' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  ls_enroll-status = p_stat.

  IF p_stat = 'C'.
    ls_enroll-comp_date = sy-datum.
  ELSE.
    ls_enroll-comp_date = '00000000'.
  ENDIF.

  UPDATE zedu_enroll FROM ls_enroll.

  IF sy-subrc = 0.
    COMMIT WORK.

    WRITE: / '교육 신청 상태가 변경되었습니다.'.
    WRITE: / '신청 ID:', p_enrid.
    WRITE: / '변경 상태:', p_stat, lv_status_text.
    WRITE: / '처리 일자:', sy-datum.
    WRITE: / '처리 시간:', sy-uzeit.

  ELSE.
    ROLLBACK WORK.
    WRITE: / '교육 신청 상태 변경에 실패했습니다.'.
    WRITE: / '신청 ID:', p_enrid.

  ENDIF.

ENDFORM.
