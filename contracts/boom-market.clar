;; Boom Market Smart Contract 
;; Implements smart-shop-trait & integrates with nft-trait

;; ========== TRAIT IMPLEMENTATIONS & IMPORTS ==========
(impl-trait .smart-shop-trait.smart-shop-trait)
(use-trait nft-trait .nft-trait.nft-trait)
(impl-trait .nft-trait.nft-trait)


;; ========== TOKEN DEFINITIONS ==========
(define-non-fungible-token boom-nft uint)


;; ========== Constants ==========
;; Core error codes
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-LIST-FULL (err u405))
(define-constant ERR-INVALID-PRINCIPAL (err u406))
(define-constant ERR-OWNER-ONLY (err u407))


;; Role error codes
(define-constant ERR-ONLY-OWNER (err u1000))
(define-constant ERR-ONLY-MANAGER (err u1001))

;; Product error codes
(define-constant ERR-PRODUCT-NOT-FOUND (err u2000))
(define-constant ERR-PRODUCT-INACTIVE (err u2001))
(define-constant ERR-INVALID-PRICE (err u2002))
(define-constant ERR-INVALID-ID (err u2003))
(define-constant ERR-PRODUCT-ADD-FAILED (err u2004))
(define-constant ERR-PRODUCT-UPDATE-FAILED (err u2005))
(define-constant ERR-PRODUCT-REMOVE-FAILED (err u2006))
(define-constant ERR-INVENTORY-UPDATE-FAILED (err u2007))

;; Order error codes
(define-constant ERR-ORDER-NOT-FOUND (err u3000))
(define-constant ERR-INVALID-ORDER-STATUS (err u3001))
(define-constant ERR-INSUFFICIENT-INVENTORY (err u3002))
(define-constant ERR-INVALID-QUANTITY (err u3003))
(define-constant ERR-PLACE-ORDER-FAILED (err u3004))

;; Input validation error codes
(define-constant ERR-INVALID-INPUT (err u4000))
(define-constant ERR-EMPTY-STRING (err u4001))

;; Log error codes
(define-constant ERR-LOG-VALIDATION-FAILED (err u5000))
(define-constant ERR-LOG-STORE-UPDATE-FAILED (err u5001))
(define-constant ERR-LOG-PRODUCT-FAILED (err u5002))
(define-constant ERR-LOG-ORDER-FAILED (err u5003))
(define-constant ERR-LOG-INVENTORY-FAILED (err u5004))
(define-constant ERR-LOG-DISCOUNT-FAILED (err u5005))
(define-constant ERR-LOG-NFT-FAILED (err u5006))
(define-constant ERR-MANAGER-ADD-FAILED (err u5007))
(define-constant ERR-MANAGER-REMOVE-FAILED (err u5008))

;; NFT error codes
(define-constant ERR-NFT-NOT-ENABLED (err u6000))
(define-constant ERR-NFT-NOT-WHITELISTED (err u6001))
(define-constant ERR-NFT-INVALID-TOKEN-ID (err u6002))
(define-constant ERR-NFT-INVALID-OWNER (err u6003))
(define-constant ERR-NFT-INVALID-RECIPIENT (err u6004))
(define-constant ERR-NFT-MINT-FAILED (err u6005))
(define-constant ERR-NFT-TRANSFER-FAILED (err u6006))
(define-constant ERR-NFT-BURN-FAILED (err u6007))
(define-constant ERR-NFT-MINTING-ORDER-FAILED (err u6008))
(define-constant ERR-INVALID-CONTRACT (err u6009))
(define-constant ERR-NOT-TOKEN-OWNER (err u6010))
(define-constant ERR-INVALID-TOKEN (err u6011))
(define-constant ERR-LOG-MINT-FAILED (err u6012))
(define-constant ERR-NFT-CONTRACT-UPDATE (err u6013))
(define-constant ERR-NFT-CONFIG-UPDATE (err u6014))
(define-constant ERR-INVALID-NFT-CONTRACT (err u6015))
(define-constant ERR-NFT-NOT-FOUND (err u6016))
(define-constant ERR-INVALID-URI (err u6017))
(define-constant ERR-URI-UPDATE-FAILED (err u6018))
(define-constant ERR-INVALID-URI-FORMAT (err u6019))

;; Discount error codes
(define-constant ERR-DISCOUNT-NOT-FOUND (err u7000))
(define-constant ERR-DISCOUNT-EXPIRED (err u7001))
(define-constant ERR-INVALID-DISCOUNT (err u7002))
(define-constant ERR-INVALID-DISCOUNT-ID (err u7003))
(define-constant ERR-DISCOUNT-FAILED (err u7004))

;; Buyer error codes
(define-constant ERR-INVALID-BUYER (err u403))
(define-constant ERR-UNAUTHORIZED-BUYER (err u404))


;; ========== DATA VARIABLES ==========
;; Store details
(define-data-var store-name (string-ascii 50) "")
(define-data-var store-description (string-ascii 200) "")
(define-data-var store-logo (string-ascii 100) "")
(define-data-var store-banner (string-ascii 100) "")

;; Counters
(define-data-var product-nonce uint u0)
(define-data-var order-nonce uint u0)
(define-data-var log-nonce uint u0)
(define-data-var discount-nonce uint u0)
(define-data-var discount-ids (list 200 uint) (list))


;; List tracking 
(define-data-var product-ids (list 200 uint) (list))
(define-data-var order-ids (list 200 uint) (list))

;; NFT token ID counter
(define-data-var last-token-id uint u0)

;; ========== DATA MAPS ==========
;; Role Management
(define-map managers principal bool)

;; Token URI storage
(define-map token-uris uint (string-ascii 200))

;; Product Management
(define-map products uint {
    name: (string-ascii 50),
    price: uint,
    description: (optional (string-ascii 200)),
    active: bool,
    inventory: uint,
    created-at: uint,
    updated-at: uint
})

;; Order Management
(define-map orders uint {
    id: uint,
    product-id: uint,
    quantity: uint,
    buyer: principal,
    status: (string-ascii 20),
    created-at: uint,
})

;; Logging System
(define-map logs uint {
    action: (string-ascii 50),
    principal: principal,
    details: (string-ascii 200),
    timestamp: uint
})

;; Discount Management
(define-map discounts uint {
    id: uint,
    product-id: uint,
    amount: uint,
    start-block: uint,
    end-block: uint,
    active: bool,
    created-at: uint,
    updated-at: uint
})

;; NFT maps
(define-map nft-contracts principal bool)
(define-map product-nfts uint {
    nft-contract: principal,
    token-uri: (optional (string-ascii 200)),
    enabled: bool
})


;; ========== PRIVATE FUNCTIONS ==========
;; ========== List Management Functions ==========
(define-private (add-to-product-list (id uint))
    (let ((current-list (var-get product-ids)))
        (begin 
            (asserts! (< (len current-list) u200) ERR-LIST-FULL)
            (asserts! (validate-id id) ERR-INVALID-ID)
            (var-set product-ids (unwrap-panic (as-max-len? (append current-list id) u200)))
            (ok true))))

(define-private (add-to-order-list (id uint))
    (let ((current-list (var-get order-ids)))
        (begin
            (asserts! (< (len current-list) u200) ERR-LIST-FULL)
            (var-set order-ids (unwrap-panic (as-max-len? (append current-list id) u200)))
            (ok true))))

;; ========== List Functions ==========
(define-private (fold-product-tuple (product-tuple {id: uint, price: uint, name: (string-ascii 50)})
                                  (result (list 200 {id: uint, price: uint, name: (string-ascii 50)})))
    (match (as-max-len? (append result product-tuple) u200)
        success success
        result))

(define-private (fold-product (id uint) (result (list 200 {id: uint, price: uint, name: (string-ascii 50)})))
    (match (map-get? products id)
        product (fold-product-tuple 
            {
                id: id,
                price: (get price product),
                name: (get name product)
            }
            result)
        result))

;; ========== Authorization Functions ==========
(define-private (is-owner)
    (is-eq tx-sender contract-owner))

(define-private (validate-principal (principal principal))
    (not (is-eq principal 'SP000000000000000000002Q6VF78)))

(define-private (is-manager)
    (default-to false (map-get? managers tx-sender)))

(define-private (can-manage)
    (or (is-owner) (is-manager)))

;; ========== Input Validation Functions ==========
(define-private (validate-price (price uint))
    (> price u0))

(define-private (validate-string-not-empty (value (string-ascii 50)))
    (not (is-eq value "")))

(define-private (validate-quantity (quantity uint))
    (> quantity u0))

(define-private (validate-id (id uint))
    (>= (var-get product-nonce) id))

(define-private (validate-string-length-200 (value (string-ascii 200)))
    (and 
        (not (is-eq value ""))
        (<= (len value) u200)))

(define-private (validate-string-length-100 (value (string-ascii 100)))
    (and 
        (not (is-eq value ""))
        (<= (len value) u100)))

(define-private (validate-optional-description (description (optional (string-ascii 200))))
    (match description
        desc (validate-string-length-200 desc)
        true))

(define-private (validate-optional-string (value (optional (string-ascii 200))))
    (match value
        desc (validate-string-length-200 desc)
        true))

(define-private (validate-token-id (token-id uint))
    (and 
        (> token-id u0)
        (<= token-id (var-get last-token-id))))

(define-private (validate-token-uri (uri (string-ascii 200)))
    (begin
        ;; Check for empty string
        (asserts! (not (is-eq uri "")) ERR-INVALID-URI-FORMAT)
        ;; Check minimum length for ipfs:// prefix
        (asserts! (>= (len uri) u7) ERR-INVALID-URI-FORMAT)
        ;; Validate prefix is ipfs://
        (asserts! (is-eq (slice? uri u0 u7) (some "ipfs://")) ERR-INVALID-URI-FORMAT)
        ;; Check remaining length after prefix
        (asserts! (> (len uri) u7) ERR-INVALID-URI-FORMAT)
        (ok true)))

(define-private (validate-product-id (id uint))
    (and 
        (< id (var-get product-nonce))
        (get active (default-to 
            {active: false} 
            (map-get? products id)))))

;; ========== Enhanced Order Processing ==========
(define-private (apply-discount (price uint))
    (ok price))

(define-private (is-discount-active (discount (optional {
    product-id: uint,
    amount: uint,
    start-block: uint,
    end-block: uint,
    active: bool
})))
    (match discount
        d (and 
            (get active d)
            (>= block-height (get start-block d))
            (<= block-height (get end-block d)))
        false))

(define-private (get-active-discount (product-id uint))
    (let ((current-block block-height))
        (match (map-get? discounts product-id)
            discount (if (and 
                            (get active discount)
                            (>= current-block (get start-block discount))
                            (<= current-block (get end-block discount)))
                        (some discount)
                        none)
            none)))

(define-private (check-discount (discount-id uint) (result (optional {
        id: uint,
        product-id: uint,
        amount: uint,
        start-block: uint,
        end-block: uint,
        active: bool,
        created-at: uint,
        updated-at: uint
    })))
    (let ((discount (map-get? discounts discount-id)))
        (match discount
            d (if (and 
                (get active d)
                (>= block-height (get start-block d))
                (<= block-height (get end-block d)))
                (some d)
                result)
            result)))

(define-private (find-active-discount (product-id uint))
    (let ((discount (map-get? discounts product-id)))
        (match discount
            d (if (and 
                (get active d)
                (>= block-height (get start-block d))
                (<= block-height (get end-block d)))
                (some d)
                none)
            none)))

;; ========== Logging Functions ==========
(define-private (add-log (action (string-ascii 50)) (details (string-ascii 200)))
    (let ((log-id (var-get log-nonce)))
        (begin
            (map-set logs log-id {
                action: action,
                principal: tx-sender,
                details: details,
                timestamp: block-height
            })
            (var-set log-nonce (+ log-id u1))
            (ok u1))))

;; ========== Order Management ==========
(define-private (create-order (order-id uint) (product-id uint) (quantity uint) (buyer principal))
    (begin
        ;; Validate order parameters
        (asserts! (validate-id order-id) ERR-INVALID-ID)
        (asserts! (validate-id product-id) ERR-INVALID-ID)
        (asserts! (validate-quantity quantity) ERR-INVALID-QUANTITY)
        (asserts! (not (is-eq buyer 'SP000000000000000000002Q6VF78)) ERR-INVALID-PARAMS)
        
        ;; Get product and calculate price
        (let ((product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND)))
            (begin
                ;; Log order validation
                (unwrap! (add-log "validate" "Order parameters validated") ERR-LOG-VALIDATION-FAILED)
                
                ;; Create the order
                (map-set orders order-id {
                    id: order-id,
                    product-id: product-id,
                    quantity: quantity,
                    buyer: buyer,
                    status: "pending",
                    created-at: block-height
                })
                
                ;; Add to order list
                (try! (add-to-order-list order-id))
                
                ;; Log order creation
                (unwrap! (add-log "create-order" "Order created") ERR-LOG-ORDER-FAILED)
                
                (ok true)
            )
        )
    )
)

(define-private (fold-order-tuple (order-tuple {id: uint, product-id: uint, quantity: uint, buyer: principal, status: (string-ascii 20)})
                                (result (list 200 {id: uint, product-id: uint, quantity: uint, buyer: principal, status: (string-ascii 20)})))
    (match (as-max-len? (append result order-tuple) u200)
        success success
        result))

(define-private (fold-order (id uint) (result (list 200 {id: uint, product-id: uint, quantity: uint, buyer: principal, status: (string-ascii 20)})))
    (match (map-get? orders id)
        order (fold-order-tuple
            {
                id: id,
                product-id: (get product-id order),
                quantity: (get quantity order),
                buyer: (get buyer order),
                status: (get status order)
            }
            result)
        result))

;; NFT helper functions
(define-private (mint-nft (recipient principal))
    (let ((token-id (+ (var-get last-token-id) u1)))
        (begin
            (try! (nft-mint? boom-nft token-id recipient))
            (var-set last-token-id token-id)
            (ok token-id))))

(define-private (mint-product-nft (product-id uint) (recipient principal))
    (let ((nft-data (map-get? product-nfts product-id)))
        (match nft-data
            data (begin
                (asserts! (get enabled data) ERR-NFT-NOT-ENABLED)
                (try! (as-contract (contract-call? .boom-nft mint recipient)))
                (unwrap! (add-log "mint-nft" "NFT minted successfully") ERR-NFT-MINT-FAILED)
                (ok true))
            ERR-NFT-NOT-FOUND)))

(define-private (is-whitelisted-nft (nft-contract principal))
    (default-to false (map-get? nft-contracts nft-contract)))

(define-private (is-whitelisted-contract (contract principal))
    (default-to false (map-get? nft-contracts contract)))

(define-private (is-valid-nft-contract (nft-contract <nft-trait>))
    (contract-call? nft-contract get-last-token-id))

(define-private (validate-uri-format (uri (string-ascii 200)))
    (let ((uri-len (len uri)))
        (and 
            (not (is-eq uri ""))  ;; not empty
            (>= uri-len u7)       ;; minimum length
            (is-eq (slice? uri u0 u7) (some "ipfs://"))  ;; starts with ipfs://
            (<= uri-len u200)     ;; max length check
            (> uri-len u7))))  

(define-private (validate-nft-contract (nft-contract principal))
    (and 
        ;; Not zero address
        (not (is-eq nft-contract 'SP000000000000000000002Q6VF78))
        ;; Not self
        (not (is-eq nft-contract (as-contract tx-sender)))
        ;; Must be whitelisted
        (default-to false (map-get? nft-contracts nft-contract))))


;; ========== PUBLIC FUNCTIONS ==========
;; ========== Store Management ==========
(define-public (update-store-info 
        (name (string-ascii 50)) 
        (description (string-ascii 200)) 
        (logo (string-ascii 100)) 
        (banner (string-ascii 100)))
    (begin
        ;; Authorization check
        (asserts! (is-owner) ERR-ONLY-OWNER)
        ;; Input validation
        (asserts! (validate-string-not-empty name) ERR-EMPTY-STRING)
        (asserts! (validate-string-length-200 description) ERR-INVALID-INPUT)
        (asserts! (validate-string-length-100 logo) ERR-INVALID-INPUT)
        (asserts! (validate-string-length-100 banner) ERR-INVALID-INPUT)
        
        ;; Update store info
        (var-set store-name name)
        (var-set store-description description)
        (var-set store-logo logo)
        (var-set store-banner banner)
        
        ;; Log the update
        (unwrap! (add-log "update-store" "Store information updated") ERR-LOG-STORE-UPDATE-FAILED)
        
        (ok true)))

;; ========== Role Management ==========
(define-public (add-manager (manager principal))
    (begin
        (asserts! (is-owner) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq manager tx-sender)) ERR-INVALID-PARAMS)
        (unwrap! (add-log "validate" "Manager validated") ERR-LOG-VALIDATION-FAILED)
        (map-set managers manager true)
        (unwrap! (add-log "add-manager" "Manager added") ERR-MANAGER-ADD-FAILED)
        (ok true)))

(define-public (remove-manager (manager principal))
    (begin
        (asserts! (is-owner) ERR-NOT-AUTHORIZED)
        (asserts! (default-to false (map-get? managers manager)) ERR-NOT-FOUND)
        (map-delete managers manager)
        (unwrap! (add-log "remove-manager" "Manager removed") ERR-MANAGER-REMOVE-FAILED)
        (ok true)))

;; ========== Product Management ==========
(define-public (add-product (id uint) (price uint) (name (string-ascii 50)) (description (optional (string-ascii 200))))
    (begin
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        (asserts! (validate-price price) ERR-INVALID-PRICE)
        (asserts! (validate-string-not-empty name) ERR-EMPTY-STRING)
        (asserts! (validate-optional-description description) ERR-INVALID-INPUT)
        
        ;; Update nonce if needed
        (if (>= id (var-get product-nonce))
            (var-set product-nonce (+ id u1))
            true)
        
        ;; Add product
        (map-set products id {
            name: name,
            price: price,
            description: description,
            active: true,
            inventory: u100,
            created-at: block-height,
            updated-at: block-height
        })
        
        (unwrap! (add-log "add-product" "Product added") ERR-PRODUCT-ADD-FAILED)
        (ok true)))

(define-public (update-product (id uint) (price uint) (name (string-ascii 50)) (description (optional (string-ascii 200))))
    (let ((existing-product (unwrap! (map-get? products id) ERR-PRODUCT-NOT-FOUND)))
        (begin
            (asserts! (can-manage) ERR-NOT-AUTHORIZED)
            (asserts! (validate-price price) ERR-INVALID-PRICE)
            (asserts! (validate-string-not-empty name) ERR-EMPTY-STRING)
            (asserts! (validate-id id) ERR-INVALID-ID)
            (asserts! (validate-optional-string description) ERR-INVALID-INPUT)
            (unwrap! (add-log "validate" "Product update validated") ERR-LOG-VALIDATION-FAILED)
            
            (map-set products id (merge existing-product {
                name: name,
                price: price,
                description: description,
                updated-at: block-height
            }))
            (unwrap! (add-log "update-product" "Product updated") ERR-PRODUCT-UPDATE-FAILED)
            (ok true))))

(define-public (remove-product (id uint))
    (let ((existing-product (unwrap! (map-get? products id) ERR-PRODUCT-NOT-FOUND)))
        (begin
            ;; Authorization check
            (asserts! (can-manage) ERR-NOT-AUTHORIZED)
            ;; Validate ID
            (asserts! (validate-id id) ERR-INVALID-ID)
            
            ;; Update product status
            (map-set products id (merge existing-product {
                active: false,
                updated-at: block-height
            }))
            
            ;; Log the action
            (unwrap! (add-log "remove-product" "Product removed") ERR-PRODUCT-REMOVE-FAILED)
            (ok true))))

(define-public (update-inventory (id uint) (quantity uint))
    (let ((product (unwrap! (map-get? products id) ERR-PRODUCT-NOT-FOUND)))
        (begin
            ;; Authorization check
            (asserts! (can-manage) ERR-NOT-AUTHORIZED)
            ;; Validate ID
            (asserts! (validate-id id) ERR-INVALID-ID)
            
            ;; Update inventory
            (map-set products id (merge product {
                inventory: quantity,
                updated-at: block-height
            }))
            
            ;; Log the update
            (unwrap! (add-log "update-inventory" "Inventory updated") ERR-INVENTORY-UPDATE-FAILED)
            (ok true))))

(define-public (place-order (product-id uint) (quantity uint) (buyer principal))
    (let (
        (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
        (total-price (* (get price product) quantity))
        (order-id (var-get order-nonce))
        (discounted-price (unwrap! (get-discounted-price product-id total-price) ERR-DISCOUNT-FAILED))
    )
    (begin
        ;; Validate order
        (asserts! (get active product) ERR-PRODUCT-INACTIVE)
        (asserts! (>= (get inventory product) quantity) ERR-INSUFFICIENT-INVENTORY)
        (asserts! (validate-quantity quantity) ERR-INVALID-QUANTITY)
        
        ;; Validate buyer
        (asserts! (is-eq tx-sender buyer) ERR-UNAUTHORIZED-BUYER)
        
        ;; Handle STX transfer with discounted price
        (try! (stx-transfer? discounted-price tx-sender (as-contract tx-sender)))
        
        ;; Create order
        (var-set order-nonce (+ order-id u1))
        
        ;; Store order
        (map-set orders order-id {
            id: order-id,
            product-id: product-id,
            quantity: quantity,
            buyer: buyer,
            status: "pending",
            created-at: block-height
        })
        
        ;; Update inventory
        (map-set products product-id (merge product {
            inventory: (- (get inventory product) quantity),
            updated-at: block-height
        }))

        ;; Update order counter and list
        (var-set order-nonce (+ order-id u1))
        (try! (add-to-order-list order-id))
        
        ;; Log the order
        (unwrap! (add-log "place-order" "Order placed successfully") ERR-PLACE-ORDER-FAILED)
        (ok true))))

(define-public (cancel-order (id uint))
    (let ((order (unwrap! (map-get? orders id) ERR-ORDER-NOT-FOUND)))
        (begin
            ;; Only allow the buyer or a manager to cancel the order
            (asserts! (or (can-manage) (is-eq tx-sender (get buyer order))) ERR-NOT-AUTHORIZED)
            ;; Only allow cancellation of pending orders
            (asserts! (is-eq (get status order) "pending") ERR-INVALID-ORDER-STATUS)
            
            ;; Return inventory - add the quantity back
            (try! (update-inventory 
                (get product-id order) 
                (+ (get inventory (unwrap! (map-get? products (get product-id order)) ERR-PRODUCT-NOT-FOUND))
                   (get quantity order))))
            
            ;; Update order status
            (map-set orders id (merge order {
                status: "cancelled"
            }))
            
            ;; Log the cancellation
            (unwrap! (add-log "cancel-order" "Order cancelled") ERR-LOG-ORDER-FAILED)
            
            (ok true))))

;; ========== Discount Management ==========
(define-public (add-discount (product-id uint) (amount uint) (start-block uint) (end-block uint))
    (let ((discount-id (var-get discount-nonce)))
        (begin
            (asserts! (can-manage) ERR-NOT-AUTHORIZED)
            (asserts! (validate-id product-id) ERR-INVALID-ID)
            (asserts! (< amount u100) ERR-INVALID-DISCOUNT)
            (asserts! (>= end-block start-block) ERR-INVALID-DISCOUNT)
            
            ;; Log validation
            (unwrap! (add-log "validate" "Discount parameters validated") ERR-LOG-VALIDATION-FAILED)
            
            ;; Add discount
            (map-set discounts discount-id {
                id: discount-id,
                amount: amount,
                product-id: product-id,
                start-block: start-block,
                end-block: end-block,
                active: true,
                created-at: block-height,
                updated-at: block-height
            })
            
            ;; Increment nonce
            (var-set discount-nonce (+ discount-id u1))
            
            ;; Log addition
            (unwrap! (add-log "add-discount" "Discount added") ERR-LOG-DISCOUNT-FAILED)
            (ok discount-id))))

;; Update update-discount with validation
(define-public (update-discount (discount-id uint) (amount uint) (end-block uint))
    (let ((discount (unwrap! (map-get? discounts discount-id) ERR-DISCOUNT-NOT-FOUND)))
        (begin
            (asserts! (can-manage) ERR-NOT-AUTHORIZED)
            (asserts! (< amount u100) ERR-INVALID-DISCOUNT)
            (asserts! (>= end-block block-height) ERR-INVALID-DISCOUNT)
            ;; Validate discount ID exists
            (asserts! (< discount-id (var-get discount-nonce)) ERR-INVALID-DISCOUNT-ID)
            
            ;; Update discount
            (map-set discounts discount-id (merge discount {
                amount: amount,
                end-block: end-block,
                updated-at: block-height
            }))
            
            ;; Log update
            (unwrap! (add-log "update-discount" "Discount updated") ERR-LOG-DISCOUNT-FAILED)
            (ok true))))

;; Update deactivate-discount with validation
(define-public (deactivate-discount (discount-id uint))
    (let ((discount (unwrap! (map-get? discounts discount-id) ERR-DISCOUNT-NOT-FOUND)))
        (begin
            (asserts! (can-manage) ERR-NOT-AUTHORIZED)
            ;; Validate discount ID exists
            (asserts! (< discount-id (var-get discount-nonce)) ERR-INVALID-DISCOUNT-ID)
            
            ;; Deactivate discount
            (map-set discounts discount-id (merge discount {
                active: false,
                updated-at: block-height
            }))
            
            ;; Log deactivation
            (unwrap! (add-log "deactivate-discount" "Discount deactivated") ERR-LOG-DISCOUNT-FAILED)
            (ok true))))

;; Update transfer function with validation
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        ;; Validate token ID
        (asserts! (validate-token-id token-id) ERR-INVALID-TOKEN)
        ;; Validate sender and recipient
        (asserts! (validate-principal sender) ERR-INVALID-PRINCIPAL)
        (asserts! (validate-principal recipient) ERR-INVALID-PRINCIPAL)
        ;; Verify ownership
        (asserts! (is-eq (some sender) (nft-get-owner? boom-nft token-id)) ERR-NOT-TOKEN-OWNER)
        ;; Verify authorization
        (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        ;; Perform transfer
        (nft-transfer? boom-nft token-id sender recipient)))

(define-public (mint (recipient principal))
    (begin
        ;; Only owner can mint
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        ;; Validate recipient
        (asserts! (validate-principal recipient) ERR-INVALID-PRINCIPAL)
        
        (let ((token-id (+ (var-get last-token-id) u1)))
            ;; Mint the NFT
            (try! (nft-mint? boom-nft token-id recipient))
            ;; Update last token ID
            (var-set last-token-id token-id)
            ;; Log the mint
            (unwrap! (add-log "mint-nft" "NFT minted successfully") ERR-LOG-MINT-FAILED)
            (ok token-id))))

;; Add this function to the boom-nft contract
(define-public (set-token-uri (token-id uint) (uri (string-ascii 200)))
    (begin
        ;; Authorization check
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        ;; Validate token exists
        (asserts! (is-some (nft-get-owner? boom-nft token-id)) ERR-NOT-FOUND)
        ;; Validate URI format
        (asserts! (validate-uri-format uri) ERR-INVALID-URI)
        ;; Set the URI after validation
        (map-set token-uris token-id uri)
        ;; Log the update
        (print {event: "set-token-uri", token-id: token-id, uri: uri})
        (ok true)))

;; NFT management functions
(define-public (set-nft-contract (nft-contract <nft-trait>) (enabled bool))
    (begin
        (asserts! (is-owner) ERR-NOT-AUTHORIZED)
        ;; Validate contract principal
        (asserts! (validate-principal (contract-of nft-contract)) ERR-INVALID-CONTRACT)
        ;; Set the contract status
        (map-set nft-contracts (contract-of nft-contract) enabled)
        ;; Log the action
        (unwrap! (add-log "set-nft-contract" "NFT contract status updated") ERR-NFT-CONTRACT-UPDATE)
        (ok true)))

(define-public (set-whitelisted-nft-contract (nft-contract <nft-trait>) (enabled bool))
    (begin
        ;; Validate caller is contract owner
        (asserts! (is-eq tx-sender contract-owner) ERR-OWNER-ONLY)
        ;; Validate contract is not null
        (asserts! (not (is-eq (contract-of nft-contract) (as-contract tx-sender))) ERR-INVALID-CONTRACT)
        ;; Set whitelist status
        (ok (map-set nft-contracts (contract-of nft-contract) enabled))))

(define-public (set-product-nft (product-id uint) (nft-contract <nft-trait>) (token-uri (optional (string-ascii 200))))
    (begin
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        (asserts! (validate-product-id product-id) ERR-INVALID-ID)
        
        ;; Validate token URI if present
        (asserts! (match token-uri
            uri (validate-uri-format uri)
            true) ERR-INVALID-URI)
        
        ;; Check if NFT contract is whitelisted
        (asserts! (default-to false (map-get? nft-contracts (contract-of nft-contract))) ERR-INVALID-NFT-CONTRACT)
        
        ;; Set NFT details for product
        (map-set product-nfts product-id {
            nft-contract: (contract-of nft-contract),
            token-uri: token-uri,
            enabled: true
        })
        
        (unwrap! (add-log "set-nft" "NFT set for product") ERR-LOG-NFT-FAILED)
        (ok true)))

(define-public (disable-product-nft (product-id uint))
    (begin
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        (asserts! (validate-id product-id) ERR-INVALID-ID)
        
        (match (map-get? product-nfts product-id)
            config (begin
                (map-set product-nfts product-id (merge config {enabled: false}))
                (unwrap! (add-log "disable-nft" "NFT disabled for product") ERR-LOG-STORE-UPDATE-FAILED)
                (ok true))
            ERR-NFT-MINT-FAILED)))




;; ========== READ-ONLY FUNCTIONS ==========
(define-read-only (list-products)
    (ok (fold fold-product (var-get product-ids) (list))))

(define-read-only (list-orders)
    (ok (fold fold-order (var-get order-ids) (list))))

;; ========== Queries ==========
(define-read-only (get-product (id uint))
    (match (map-get? products id)
        product (ok {
            id: id,
            price: (get price product),
            name: (get name product),
            description: (get description product)
        })
        ERR-PRODUCT-NOT-FOUND))

(define-read-only (get-inventory (id uint))
    (match (map-get? products id)
        product (ok (get inventory product))
        ERR-PRODUCT-NOT-FOUND))

(define-read-only (get-order (id uint))
    (match (map-get? orders id)
        order (ok {
            id: (get id order),
            product-id: (get product-id order),
            quantity: (get quantity order),
            buyer: (get buyer order),
            status: (get status order)
        })
        ERR-ORDER-NOT-FOUND))

(define-read-only (get-discount (discount-id uint))
    (ok (map-get? discounts discount-id)))

(define-read-only (get-discounted-price (product-id uint) (original-price uint))
    (let (
        (discount-data (map-get? discounts u0))  ;; Look up discount ID 0 directly
    )
    (match discount-data
        discount 
            (if (and 
                (get active discount)
                (is-eq product-id (get product-id discount))
                (>= block-height (get start-block discount))
                (<= block-height (get end-block discount)))
                ;; Apply discount - fixed calculation
                (ok (- original-price (/ (* original-price (get amount discount)) u100)))
                (ok original-price))
        (ok original-price))))

;; NFT trait implementation functions
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id)))

(define-read-only (get-token-uri (token-id uint))
    (ok (map-get? token-uris token-id)))

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? boom-nft token-id)))

;; Read-only NFT functions
(define-read-only (get-product-nft (product-id uint))
    (map-get? product-nfts product-id))

(define-read-only (is-nft-enabled (product-id uint))
    (ok (default-to false (get enabled (map-get? product-nfts product-id)))))
