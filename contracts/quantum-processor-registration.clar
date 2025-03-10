;; Quantum Processor Registration Contract
;; Registers and manages quantum processors in the network

(define-data-var admin principal tx-sender)

;; Data structure for quantum processors
(define-map quantum-processors
  { processor-id: uint }
  {
    processor-name: (string-ascii 100),
    owner: principal,
    qubits: uint,
    coherence-time: uint,
    error-rate: uint,
    location: (string-ascii 100),
    registration-time: uint,
    last-maintenance: uint,
    status: (string-ascii 20)
  }
)

;; Processor maintenance records
(define-map maintenance-records
  { record-id: uint }
  {
    processor-id: uint,
    maintainer: principal,
    maintenance-type: (string-ascii 50),
    previous-error-rate: uint,
    new-error-rate: uint,
    timestamp: uint
  }
)

;; Counter for processor IDs
(define-data-var next-processor-id uint u1)
;; Counter for maintenance record IDs
(define-data-var next-record-id uint u1)

;; Register a new quantum processor
(define-public (register-processor
  (processor-name (string-ascii 100))
  (qubits uint)
  (coherence-time uint)
  (error-rate uint)
  (location (string-ascii 100)))
  (let ((processor-id (var-get next-processor-id)))
    (map-set quantum-processors
      { processor-id: processor-id }
      {
        processor-name: processor-name,
        owner: tx-sender,
        qubits: qubits,
        coherence-time: coherence-time,
        error-rate: error-rate,
        location: location,
        registration-time: block-height,
        last-maintenance: block-height,
        status: "active"
      }
    )
    (var-set next-processor-id (+ processor-id u1))
    (ok processor-id)
  )
)

;; Update processor status
(define-public (update-processor-status (processor-id uint) (new-status (string-ascii 20)))
  (let (
    (processor (default-to
      {
        processor-name: "",
        owner: tx-sender,
        qubits: u0,
        coherence-time: u0,
        error-rate: u0,
        location: "",
        registration-time: u0,
        last-maintenance: u0,
        status: ""
      }
      (map-get? quantum-processors { processor-id: processor-id })))
    )

    ;; Check if sender is owner
    (asserts! (is-eq tx-sender (get owner processor)) (err u403))

    ;; Update processor status
    (map-set quantum-processors
      { processor-id: processor-id }
      (merge processor { status: new-status })
    )

    (ok true)
  )
)

;; Perform maintenance on a processor
(define-public (perform-maintenance
  (processor-id uint)
  (maintenance-type (string-ascii 50))
  (new-error-rate uint))
  (let (
    (processor (default-to
      {
        processor-name: "",
        owner: tx-sender,
        qubits: u0,
        coherence-time: u0,
        error-rate: u0,
        location: "",
        registration-time: u0,
        last-maintenance: u0,
        status: ""
      }
      (map-get? quantum-processors { processor-id: processor-id })))
    (record-id (var-get next-record-id))
    (previous-error-rate (get error-rate processor))
    )

    ;; Check if sender is owner
    (asserts! (is-eq tx-sender (get owner processor)) (err u403))

    ;; Record maintenance
    (map-set maintenance-records
      { record-id: record-id }
      {
        processor-id: processor-id,
        maintainer: tx-sender,
        maintenance-type: maintenance-type,
        previous-error-rate: previous-error-rate,
        new-error-rate: new-error-rate,
        timestamp: block-height
      }
    )

    ;; Update processor
    (map-set quantum-processors
      { processor-id: processor-id }
      (merge processor {
        error-rate: new-error-rate,
        last-maintenance: block-height
      })
    )

    (var-set next-record-id (+ record-id u1))
    (ok record-id)
  )
)

;; Get processor details
(define-read-only (get-processor (processor-id uint))
  (map-get? quantum-processors { processor-id: processor-id })
)

;; Get maintenance record
(define-read-only (get-maintenance-record (record-id uint))
  (map-get? maintenance-records { record-id: record-id })
)

;; Check if processor is available
(define-read-only (is-processor-available (processor-id uint))
  (let (
    (processor (default-to
      {
        processor-name: "",
        owner: tx-sender,
        qubits: u0,
        coherence-time: u0,
        error-rate: u0,
        location: "",
        registration-time: u0,
        last-maintenance: u0,
        status: ""
      }
      (map-get? quantum-processors { processor-id: processor-id })))
    )
    (is-eq (get status processor) "active")
  )
)

