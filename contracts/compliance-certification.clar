;; Financial Services Compliance Training Contract
;; Manages course development, certification tracking, policy updates, and audit documentation

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-COURSE (err u101))
(define-constant ERR-INVALID-CERT (err u102))
(define-constant MAX-COURSES u1000)

(define-data-var course-counter uint u0)
(define-data-var cert-counter uint u0)
(define-data-var total-certified uint u0)

(define-map courses
  { course-id: uint }
  {
    title: (string-ascii 128),
    category: (string-ascii 32),
    duration-hours: uint,
    status: (string-ascii 16),
    created-at: uint
  }
)

(define-map certifications
  { cert-id: uint }
  {
    employee: principal,
    course-id: uint,
    completion-date: uint,
    expiration-date: uint,
    score: uint
  }
)

(define-map policy-versions
  { policy-id: uint }
  {
    policy-name: (string-ascii 128),
    version: uint,
    effective-date: uint,
    updated-at: uint
  }
)

(define-map audit-logs
  { audit-id: uint }
  {
    employee: principal,
    action: (string-ascii 64),
    timestamp: uint,
    details: (string-ascii 256)
  }
)

(define-public (create-course
  (title (string-ascii 128))
  (category (string-ascii 32))
  (duration-hours uint)
)
  (let
    (
      (new-id (+ (var-get course-counter) u1))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (< new-id MAX-COURSES) ERR-INVALID-COURSE)
    (map-set courses
      { course-id: new-id }
      {
        title: title,
        category: category,
        duration-hours: duration-hours,
        status: "active",
        created-at: burn-block-height
      }
    )
    (var-set course-counter new-id)
    (ok new-id)
  )
)

(define-public (issue-certification
  (employee-addr principal)
  (course-id uint)
  (score uint)
  (validity-days uint)
)
  (let
    (
      (course (map-get? courses { course-id: course-id }))
      (cert-id (+ (var-get cert-counter) u1))
    )
    (match course
      course-data
      (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (and (>= score u0) (<= score u100)) ERR-INVALID-CERT)
        (map-set certifications
          { cert-id: cert-id }
          {
            employee: employee-addr,
            course-id: course-id,
            completion-date: burn-block-height,
            expiration-date: (+ burn-block-height validity-days),
            score: score
          }
        )
        (var-set cert-counter cert-id)
        (var-set total-certified (+ (var-get total-certified) u1))
        (ok cert-id)
      )
      ERR-INVALID-COURSE
    )
  )
)

(define-public (update-policy
  (policy-name (string-ascii 128))
  (version uint)
)
  (let
    (
      (policy-id (+ (var-get cert-counter) u1))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set policy-versions
      { policy-id: policy-id }
      {
        policy-name: policy-name,
        version: version,
        effective-date: burn-block-height,
        updated-at: burn-block-height
      }
    )
    (ok policy-id)
  )
)

(define-public (log-audit
  (employee-addr principal)
  (action (string-ascii 64))
  (details (string-ascii 256))
)
  (let
    (
      (audit-id (+ (var-get cert-counter) u1))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set audit-logs
      { audit-id: audit-id }
      {
        employee: employee-addr,
        action: action,
        timestamp: burn-block-height,
        details: details
      }
    )
    (ok audit-id)
  )
)

(define-public (verify-certification (cert-id uint))
  (let
    (
      (cert (map-get? certifications { cert-id: cert-id }))
    )
    (match cert
      cert-data
      (ok (>= (get expiration-date cert-data) burn-block-height))
      ERR-INVALID-CERT
    )
  )
)

(define-read-only (get-course (course-id uint))
  (map-get? courses { course-id: course-id })
)

(define-read-only (get-certification (cert-id uint))
  (map-get? certifications { cert-id: cert-id })
)

(define-read-only (get-policy (policy-id uint))
  (map-get? policy-versions { policy-id: policy-id })
)

(define-read-only (get-audit (audit-id uint))
  (map-get? audit-logs { audit-id: audit-id })
)

(define-read-only (get-total-certified)
  (var-get total-certified)
)

