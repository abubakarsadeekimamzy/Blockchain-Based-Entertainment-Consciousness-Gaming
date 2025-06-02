;; Community Building Contract
;; Facilitates consciousness gaming communities

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_COMMUNITY_NOT_FOUND (err u501))
(define-constant ERR_ALREADY_MEMBER (err u502))
(define-constant ERR_NOT_MEMBER (err u503))
(define-constant ERR_INVALID_PARAMETERS (err u504))

;; Community data
(define-map communities
  { community-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    member-count: uint,
    consciousness-focus: (string-ascii 50),
    created-at: uint,
    active: bool
  }
)

;; Community memberships
(define-map community-members
  { community-id: uint, member: principal }
  {
    joined-at: uint,
    contribution-score: uint,
    role: (string-ascii 20)
  }
)

;; Community events
(define-map community-events
  { community-id: uint, event-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    scheduled-at: uint,
    duration: uint,
    organizer: principal
  }
)

;; Counters
(define-data-var community-counter uint u0)
(define-data-var event-counter uint u0)

;; Create a new community
(define-public (create-community
  (name (string-ascii 100))
  (description (string-ascii 500))
  (consciousness-focus (string-ascii 50))
)
  (let ((community-id (+ (var-get community-counter) u1)))
    (map-set communities
      { community-id: community-id }
      {
        name: name,
        description: description,
        creator: tx-sender,
        member-count: u1,
        consciousness-focus: consciousness-focus,
        created-at: block-height,
        active: true
      }
    )

    ;; Add creator as first member
    (map-set community-members
      { community-id: community-id, member: tx-sender }
      {
        joined-at: block-height,
        contribution-score: u100,
        role: "creator"
      }
    )

    (var-set community-counter community-id)
    (ok community-id)
  )
)

;; Join a community
(define-public (join-community (community-id uint))
  (let ((community-data (unwrap! (map-get? communities { community-id: community-id }) ERR_COMMUNITY_NOT_FOUND)))
    (asserts! (get active community-data) ERR_COMMUNITY_NOT_FOUND)
    (asserts! (is-none (map-get? community-members { community-id: community-id, member: tx-sender })) ERR_ALREADY_MEMBER)

    ;; Add member
    (map-set community-members
      { community-id: community-id, member: tx-sender }
      {
        joined-at: block-height,
        contribution-score: u0,
        role: "member"
      }
    )

    ;; Update member count
    (map-set communities
      { community-id: community-id }
      (merge community-data { member-count: (+ (get member-count community-data) u1) })
    )

    (ok true)
  )
)

;; Create community event
(define-public (create-event
  (community-id uint)
  (title (string-ascii 100))
  (description (string-ascii 300))
  (scheduled-at uint)
  (duration uint)
)
  (let (
    (community-data (unwrap! (map-get? communities { community-id: community-id }) ERR_COMMUNITY_NOT_FOUND))
    (member-data (unwrap! (map-get? community-members { community-id: community-id, member: tx-sender }) ERR_NOT_MEMBER))
    (event-id (+ (var-get event-counter) u1))
  )
    (asserts! (> scheduled-at block-height) ERR_INVALID_PARAMETERS)

    (map-set community-events
      { community-id: community-id, event-id: event-id }
      {
        title: title,
        description: description,
        scheduled-at: scheduled-at,
        duration: duration,
        organizer: tx-sender
      }
    )

    (var-set event-counter event-id)
    (ok event-id)
  )
)

;; Update contribution score
(define-public (update-contribution (community-id uint) (member principal) (score-increment uint))
  (let (
    (community-data (unwrap! (map-get? communities { community-id: community-id }) ERR_COMMUNITY_NOT_FOUND))
    (member-data (unwrap! (map-get? community-members { community-id: community-id, member: member }) ERR_NOT_MEMBER))
    (caller-data (unwrap! (map-get? community-members { community-id: community-id, member: tx-sender }) ERR_NOT_MEMBER))
  )
    ;; Only creator can update contribution scores
    (asserts! (is-eq tx-sender (get creator community-data)) ERR_UNAUTHORIZED)

    (map-set community-members
      { community-id: community-id, member: member }
      (merge member-data { contribution-score: (+ (get contribution-score member-data) score-increment) })
    )
    (ok true)
  )
)

;; Get community info
(define-read-only (get-community (community-id uint))
  (map-get? communities { community-id: community-id })
)

;; Get member info
(define-read-only (get-member-info (community-id uint) (member principal))
  (map-get? community-members { community-id: community-id, member: member })
)

;; Get community event
(define-read-only (get-community-event (community-id uint) (event-id uint))
  (map-get? community-events { community-id: community-id, event-id: event-id })
)

;; Get total communities
(define-read-only (get-total-communities)
  (var-get community-counter)
)
