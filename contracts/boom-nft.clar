;; SIP009 NFT implementation for Boom Market
(impl-trait .nft-trait.nft-trait)

;; Storage
(define-non-fungible-token boom-nft uint)
(define-map token-uris uint (string-ascii 256))

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
(define-constant ERR-TOKEN-EXISTS (err u102))
(define-constant ERR-TOKEN-NOT-FOUND (err u103))
(define-constant ERR-INVALID-RECIPIENT (err u104))
(define-constant ERR-INVALID-URI (err u105))

;; Variables
(define-data-var last-token-id uint u0)

;; Private functions
(define-private (is-token-owner (token-id uint) (sender principal))
    (is-eq sender (unwrap! (nft-get-owner? boom-nft token-id) false)))

;; SIP009 Functions
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        ;; Validate sender owns the token
        (asserts! (is-token-owner token-id sender) ERR-NOT-TOKEN-OWNER)
        ;; Validate sender is tx-sender
        (asserts! (is-eq tx-sender sender) ERR-NOT-TOKEN-OWNER)
        ;; Validate recipient is not null
        (asserts! (not (is-eq recipient (as-contract tx-sender))) ERR-INVALID-RECIPIENT)
        ;; Perform transfer
        (nft-transfer? boom-nft token-id sender recipient)))

(define-public (get-last-token-id)
    (ok (var-get last-token-id)))

(define-read-only (get-token-uri (token-id uint))
    (ok (map-get? token-uris token-id)))

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? boom-nft token-id)))

;; Mint function - only contract owner can mint
(define-public (mint (recipient principal))
    (let ((token-id (+ (var-get last-token-id) u1)))
        ;; Validate caller is contract owner
        (asserts! (is-eq tx-sender contract-owner) ERR-OWNER-ONLY)
        ;; Validate recipient is not null
        (asserts! (not (is-eq recipient (as-contract tx-sender))) ERR-INVALID-RECIPIENT)
        ;; Mint token
        (try! (nft-mint? boom-nft token-id recipient))
        ;; Update last token ID
        (var-set last-token-id token-id)
        (ok token-id)))

;; URI management
(define-public (set-token-uri (token-id uint) (uri (string-ascii 256)))
    (begin
        ;; Authorization check
        (asserts! (is-eq tx-sender contract-owner) ERR-OWNER-ONLY)
        ;; Validate token exists
        (asserts! (is-some (nft-get-owner? boom-nft token-id)) ERR-TOKEN-NOT-FOUND)
        ;; Validate URI format
        (asserts! (validate-uri-format uri) ERR-INVALID-URI)
        ;; Set the URI after validation
        (map-set token-uris token-id uri)
        ;; Log the update
        (print {event: "set-token-uri", token-id: token-id, uri: uri})
        (ok true)))

;; Add URI format validation
(define-private (validate-uri-format (uri (string-ascii 256)))
    (and 
        (not (is-eq uri ""))
        (>= (len uri) u7)
        (is-eq (slice? uri u0 u7) (some "ipfs://"))
        (<= (len uri) u256)))