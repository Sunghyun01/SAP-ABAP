*-----------------------------------------------------------------------
* Local Helper Class - Status
*-----------------------------------------------------------------------
* lcl_status_helper
* - 상태값 관련 공통 로직을 모아둔 로컬 클래스
* - ZBP_R_ZEDU_ENROLL 클래스 안에서만 쓰는 보조 클래스
*-----------------------------------------------------------------------
CLASS lcl_status_helper DEFINITION FINAL.

  PUBLIC SECTION.

    " CONSTANTS
    " - 변하지 않는 고정값 선언
    " - 상태값 C/N/X를 하드코딩하지 않고 이름으로 관리하기 위해 사용
    CONSTANTS: gc_completed     TYPE zedu_enroll-status VALUE 'C',
               gc_not_completed TYPE zedu_enroll-status VALUE 'N',
               gc_cancelled     TYPE zedu_enroll-status VALUE 'X'.

    " CLASS-METHODS
    " - 객체 생성 없이 클래스명=>메서드명 으로 바로 호출 가능한 메서드
    "
    " IMPORTING
    " - 메서드로 입력받는 값
    "
    " RETURNING
    " - 메서드 실행 후 반환하는 값
    CLASS-METHODS get_comp_date
      IMPORTING iv_status           TYPE zedu_enroll-status
      RETURNING VALUE(rv_comp_date) TYPE zedu_enroll-comp_date.

ENDCLASS.


*-----------------------------------------------------------------------
* lcl_status_helper 구현부
*-----------------------------------------------------------------------
CLASS lcl_status_helper IMPLEMENTATION.

  METHOD get_comp_date.

    " CASE
    " - iv_status 값에 따라 분기 처리
    "
    " 이수 상태 C일 때만 이수일자를 오늘 날짜로 세팅
    " 그 외 미이수/취소는 이수일자를 초기화
    CASE iv_status.
      WHEN gc_completed.
        rv_comp_date = sy-datum.        " sy-datum = SAP 시스템 현재 날짜

      WHEN OTHERS.
        rv_comp_date = '00000000'.      " 날짜 초기값
    ENDCASE.

  ENDMETHOD.

ENDCLASS.


*-----------------------------------------------------------------------
* Local Helper Class - Log
*-----------------------------------------------------------------------
* lcl_log_helper
* - ZEDU_LOG 저장 전용 보조 클래스
* - 상태 변경 로그 메시지 생성
* - LOG_ID 생성
* - ZEDU_LOG INSERT 처리
*-----------------------------------------------------------------------
CLASS lcl_log_helper DEFINITION FINAL.

  PUBLIC SECTION.

    " 상태 변경 로그 저장 메서드
    "
    " iv_ 로 시작하는 변수명은 보통 Importing Value 의미로 많이 사용
    " iv_enroll_id  : 신청 ID
    " iv_course_id  : 과정 ID
    " iv_new_status : 변경 후 상태값
    CLASS-METHODS save_status_change
      IMPORTING iv_enroll_id  TYPE zedu_enroll-enroll_id
                iv_course_id  TYPE zedu_enroll-course_id
                iv_new_status TYPE zedu_enroll-status.

  PRIVATE SECTION.

    " 로그 메시지 생성 메서드
    " 외부에서 직접 호출할 필요 없으므로 PRIVATE SECTION에 둠
    CLASS-METHODS build_message
      IMPORTING iv_old_status TYPE zedu_enroll-status
                iv_new_status TYPE zedu_enroll-status
      RETURNING VALUE(rv_msg) TYPE zedu_log-msg_text.

ENDCLASS.


*-----------------------------------------------------------------------
* lcl_log_helper 구현부
*-----------------------------------------------------------------------
CLASS lcl_log_helper IMPLEMENTATION.

  METHOD save_status_change.

    " DATA
    " - 지역 변수 선언
    " - 이 METHOD 안에서만 사용됨
    DATA: ls_log        TYPE zedu_log,                " ZEDU_LOG 한 건 구조
          lv_log_id     TYPE zedu_log-log_id,         " 로그 ID
          lv_prefix     TYPE c LENGTH 17,             " LOG + 날짜 + 시간
          lv_seq        TYPE n LENGTH 3,              " 중복 방지 순번 001~999
          lv_old_status TYPE zedu_enroll-status,      " 변경 전 상태
          lv_msg        TYPE zedu_log-msg_text.       " 로그 메시지

    CLEAR lv_old_status.

    " 현재 DB에 저장된 기존 상태값 조회
    SELECT SINGLE status
      FROM zedu_enroll
      INTO lv_old_status
      WHERE enroll_id = iv_enroll_id.

    " 기존 상태와 변경 상태가 같으면 로그를 남기지 않음
    IF sy-subrc = 0 AND lv_old_status = iv_new_status.
      RETURN.
    ENDIF.

    " 로그 메시지 생성
    lv_msg = build_message(
      iv_old_status = lv_old_status
      iv_new_status = iv_new_status
    ).

    " 로그 ID Prefix 생성
    " 예: LOG20260806162830
    CONCATENATE 'LOG' sy-datum sy-uzeit INTO lv_prefix.

    " 같은 초에 여러 로그가 생길 수 있으므로 뒤에 001~999 순번을 붙임
    DO 999 TIMES.

      lv_seq = sy-index.
      CONCATENATE lv_prefix lv_seq INTO lv_log_id.

      CLEAR ls_log.

      " ZEDU_LOG 테이블에 들어갈 값 세팅
      ls_log-mandt        = sy-mandt.         " Client
      ls_log-log_id       = lv_log_id.        " 로그 ID
      ls_log-process_type = 'S'.              " S = 상태 변경
      ls_log-ref_id       = iv_enroll_id.     " 참조 ID
      ls_log-course_id    = iv_course_id.     " 과정 ID
      ls_log-enroll_id    = iv_enroll_id.     " 신청 ID
      ls_log-msg_type     = 'S'.              " S = 성공 메시지
      ls_log-msg_text     = lv_msg.           " 로그 메시지
      ls_log-program_id   = sy-repid.         " 실행 프로그램 ID
      ls_log-created_by   = sy-uname.         " 생성자
      ls_log-created_date = sy-datum.         " 생성일
      ls_log-created_time = sy-uzeit.         " 생성시간

      " 로그 테이블 INSERT
      INSERT zedu_log FROM ls_log.

      " INSERT 성공하면 반복 종료
      IF sy-subrc = 0.
        EXIT.
      ENDIF.

    ENDDO.

  ENDMETHOD.


  METHOD build_message.

    " 상태 변경 메시지 생성
    " 예: 교육 신청 상태 변경: A -> C
    CONCATENATE '교육 신청 상태 변경:'
                iv_old_status
                '->'
                iv_new_status
      INTO rv_msg SEPARATED BY space.

  ENDMETHOD.

ENDCLASS.


*-----------------------------------------------------------------------
* RAP Handler Class
*-----------------------------------------------------------------------
* lhc_enrollment
* - RAP Framework가 직접 호출하는 Handler 클래스
* - Behavior Definition에 선언한 Action, Determination을 구현하는 곳
*
* cl_abap_behavior_handler
* - RAP Handler 클래스가 상속받아야 하는 SAP 표준 클래스
*-----------------------------------------------------------------------
CLASS lhc_enrollment DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    " set_completed
    " - Behavior Definition의 action set_completed 구현
    " - Fiori 버튼 [이수 처리] 클릭 시 실행됨
    METHODS set_completed FOR MODIFY
      IMPORTING keys FOR ACTION Enrollment~set_completed RESULT result.

    " set_not_completed
    " - Fiori 버튼 [미이수 처리] 클릭 시 실행됨
    METHODS set_not_completed FOR MODIFY
      IMPORTING keys FOR ACTION Enrollment~set_not_completed RESULT result.

    " set_cancelled
    " - Fiori 버튼 [신청 취소] 클릭 시 실행됨
    METHODS set_cancelled FOR MODIFY
      IMPORTING keys FOR ACTION Enrollment~set_cancelled RESULT result.

    " save_log
    " - Behavior Definition의 determination save_log 구현
    " - update 발생 시 로그 저장용으로 실행됨
    METHODS save_log FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Enrollment~save_log.

ENDCLASS.


*-----------------------------------------------------------------------
* RAP Handler Class 구현부
*-----------------------------------------------------------------------
CLASS lhc_enrollment IMPLEMENTATION.

  METHOD set_completed.

    " MODIFY ENTITIES
    " - RAP BO 데이터를 수정하는 구문
    " - 직접 UPDATE zedu_enroll 하지 않고 RAP Framework를 통해 수정
    "
    " IN LOCAL MODE
    " - 같은 Behavior Pool 내부에서 로컬 트랜잭션으로 처리
    "
    " ENTITY Enrollment
    " - Behavior Definition에서 alias로 선언한 Entity 이름
    "
    " UPDATE FIELDS ( Status CompDate )
    " - Status, CompDate 필드만 변경
    "
    " keys
    " - Fiori에서 선택한 행의 키 정보
    "
    " %tky
    " - RAP 내부 기술 키
    " - 어떤 행을 수정할지 식별하는 데 사용
    MODIFY ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        UPDATE FIELDS ( Status CompDate )
        WITH VALUE #(
          FOR key IN keys
          (
            %tky     = key-%tky
            Status   = lcl_status_helper=>gc_completed
            CompDate = lcl_status_helper=>get_comp_date(
                         lcl_status_helper=>gc_completed
                       )
          )
        )
      FAILED failed
      REPORTED reported.

    " Action 실행 후 변경된 데이터를 다시 읽어서 result에 담음
    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId EmpId EmpName DeptName Status ReqDate CompDate CreatedBy CreatedDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    " result
    " - Action 실행 후 Fiori/OData 쪽으로 돌려줄 결과
    " - result [1] $self 로 선언했기 때문에 현재 Entity 데이터를 반환
    "
    " %param
    " - Action result payload에 들어갈 실제 Entity 데이터
    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


  METHOD set_not_completed.

    " 미이수 처리
    " Status = N
    " CompDate = 00000000
    MODIFY ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        UPDATE FIELDS ( Status CompDate )
        WITH VALUE #(
          FOR key IN keys
          (
            %tky     = key-%tky
            Status   = lcl_status_helper=>gc_not_completed
            CompDate = lcl_status_helper=>get_comp_date(
                         lcl_status_helper=>gc_not_completed
                       )
          )
        )
      FAILED failed
      REPORTED reported.

    " 변경 후 데이터 다시 조회
    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId EmpId EmpName DeptName Status ReqDate CompDate CreatedBy CreatedDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    " Action 결과 반환
    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


  METHOD set_cancelled.

    " 신청 취소 처리
    " Status = X
    " CompDate = 00000000
    MODIFY ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        UPDATE FIELDS ( Status CompDate )
        WITH VALUE #(
          FOR key IN keys
          (
            %tky     = key-%tky
            Status   = lcl_status_helper=>gc_cancelled
            CompDate = lcl_status_helper=>get_comp_date(
                         lcl_status_helper=>gc_cancelled
                       )
          )
        )
      FAILED failed
      REPORTED reported.

    " 변경 후 데이터 다시 조회
    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId EmpId EmpName DeptName Status ReqDate CompDate CreatedBy CreatedDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    " Action 결과 반환
    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


  METHOD save_log.

    " Determination에서 변경 대상 데이터를 읽음
    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_enroll).

    " 변경 대상 건수만큼 반복하면서 로그 저장
    LOOP AT lt_enroll INTO DATA(ls_enroll).

      lcl_log_helper=>save_status_change(
        iv_enroll_id  = ls_enroll-EnrollId
        iv_course_id  = ls_enroll-CourseId
        iv_new_status = ls_enroll-Status
      ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
