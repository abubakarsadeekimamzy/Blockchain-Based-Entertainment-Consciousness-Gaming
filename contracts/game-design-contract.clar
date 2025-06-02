;; Game Design Contract
;; Manages consciousness gaming experiences

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_GAME_NOT_FOUND (err u201))
(define-constant ERR_INVALID_PARAMETERS (err u202))

;; Game data structure
(define-map games
  { game-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    consciousness-level: uint,
    wellbeing-score: uint,
    created-at: uint,
    active: bool
  }
)

;; Game counter
(define-data-var game-counter uint u0)

;; Create a new consciousness game
(define-public (create-game
  (title (string-ascii 100))
  (description (string-ascii 500))
  (consciousness-level uint)
)
  (let ((game-id (+ (var-get game-counter) u1)))
    (asserts! (> consciousness-level u0) ERR_INVALID_PARAMETERS)
    (asserts! (<= consciousness-level u10) ERR_INVALID_PARAMETERS)

    (map-set games
      { game-id: game-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        consciousness-level: consciousness-level,
        wellbeing-score: u0,
        created-at: block-height,
        active: true
      }
    )

    (var-set game-counter game-id)
    (ok game-id)
  )
)

;; Get game details
(define-read-only (get-game (game-id uint))
  (map-get? games { game-id: game-id })
)

;; Update game status
(define-public (toggle-game-status (game-id uint))
  (let ((game-data (unwrap! (map-get? games { game-id: game-id }) ERR_GAME_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator game-data)) ERR_UNAUTHORIZED)

    (map-set games
      { game-id: game-id }
      (merge game-data { active: (not (get active game-data)) })
    )
    (ok true)
  )
)

;; Update wellbeing score
(define-public (update-wellbeing-score (game-id uint) (new-score uint))
  (let ((game-data (unwrap! (map-get? games { game-id: game-id }) ERR_GAME_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator game-data)) ERR_UNAUTHORIZED)
    (asserts! (<= new-score u100) ERR_INVALID_PARAMETERS)

    (map-set games
      { game-id: game-id }
      (merge game-data { wellbeing-score: new-score })
    )
    (ok true)
  )
)

;; Get total games count
(define-read-only (get-total-games)
  (var-get game-counter)
)
