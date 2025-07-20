;; gas-director.clar
;; Gas Optimization and Contract Verification Platform

;; This contract manages the certification and optimization of smart contracts on the Stacks blockchain.
;; It provides functionality for:
;; 1. Registering and managing qualified gas optimization experts
;; 2. Submitting contracts for gas efficiency review
;; 3. Issuing optimization certifications with metadata
;; 4. Verifying contract optimization status
;; 5. Managing expert reputation and efficiency scores

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-REGISTERED (err u102))
(define-constant ERR-INVALID-RATING (err u103))
(define-constant ERR-ALREADY-OPTIMIZED (err u104))
(define-constant ERR-NOT-OPTIMIZED (err u105))
(define-constant ERR-INVALID-STATUS (err u106))
(define-constant ERR-INVALID-PARAMETERS (err u107))
(define-constant ERR-CONTRACT-NOT-FOUND (err u108))

;; Data structures

;; Admin control
(define-data-var platform-owner principal tx-sender)

;; Expert registry: maps gas optimization expert principal to their details and status
(define-map gas-experts
  principal
  {
    name: (string-ascii 64),
    company: (string-ascii 64),
    website: (string-ascii 128),
    efficiency-score: uint,
    optimization-count: uint,
    status: (string-ascii 10),
    approved-at: uint
  }
)

;; Optimization requests made by contract owners
(define-map optimization-requests
  {
    contract-id: principal,
    version: (string-ascii 16)
  }
  {
    owner: principal,
    description: (string-ascii 256),
    repository-url: (string-ascii 128),
    request-time: uint,
    status: (string-ascii 10)
  }
)

;; Optimizations issued by gas efficiency experts
(define-map contract-optimizations
  {
    contract-id: principal,
    version: (string-ascii 16)
  }
  {
    expert: principal,
    gas-reduction-percent: uint,
    optimization-report-url: (string-ascii 128),
    optimization-time: uint,
    valid-until: uint,
    notes: (string-ascii 256)
  }
)

;; Private functions

;; Check if caller is the platform owner
(define-private (is-platform-owner)
  (is-eq tx-sender (var-get platform-owner))
)

;; Check if caller is a registered and active gas optimization expert
(define-private (is-active-expert (expert principal))
  (match (map-get? gas-experts expert)
    expert-data (is-eq (get status expert-data) "active")
    false
  )
)

;; Read-only functions

;; Check if a contract is gas optimized
(define-read-only (is-contract-optimized (contract-id principal) (version (string-ascii 16)))
  (is-some (map-get? contract-optimizations { contract-id: contract-id, version: version }))
)

;; Get gas expert details
(define-read-only (get-expert-details (expert principal))
  (map-get? gas-experts expert)
)

;; Get optimization details for a contract
(define-read-only (get-optimization-details (contract-id principal) (version (string-ascii 16)))
  (map-get? contract-optimizations { contract-id: contract-id, version: version })
)

;; Public functions

;; Transfer platform ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-platform-owner) ERR-UNAUTHORIZED)
    (ok (var-set platform-owner new-owner))
  )
)

;; Public verification endpoint that any user can call to check if a contract is optimized
(define-public (verify-contract-optimization (contract-id principal) (version (string-ascii 16)))
  (ok (is-contract-optimized contract-id version))
)

;; Public endpoint to get detailed optimization information for a contract
(define-public (get-optimization-info (contract-id principal) (version (string-ascii 16)))
  (match (map-get? contract-optimizations { contract-id: contract-id, version: version })
    optimization-data
      (let ((expert-data (default-to 
                          { 
                            name: "", company: "", website: "", efficiency-score: u0,
                            optimization-count: u0, status: "", approved-at: u0
                          }
                          (map-get? gas-experts (get expert optimization-data)))))
        (ok {
          optimized: true,
          expert: (get expert optimization-data),
          expert-name: (get name expert-data),
          expert-company: (get company expert-data),
          gas-reduction: (get gas-reduction-percent optimization-data),
          optimization-time: (get optimization-time optimization-data),
          valid-until: (get valid-until optimization-data),
          expert-efficiency-score: (get efficiency-score expert-data)
        }))
    (ok { optimized: false, expert: tx-sender, expert-name: "", expert-company: "",
          gas-reduction: u0, optimization-time: u0, valid-until: u0, expert-efficiency-score: u0 })
  )
)