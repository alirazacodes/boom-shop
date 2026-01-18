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
(define-constant ERR-MANAGER-VALIDATION-FAILED (err u408))

;; Product error codes
(define-constant ERR-PRODUCT-NOT-FOUND (err u2000))
(define-constant ERR-PRODUCT-INACTIVE (err u2001))
(define-constant ERR-INVALID-PRICE (err u2002))
(define-constant ERR-INVALID-ID (err u2003))
(define-constant ERR-PRODUCT-ADD-FAILED (err u2004))
(define-constant ERR-PRODUCT-UPDATE-FAILED (err u2005))
(define-constant ERR-PRODUCT-REMOVE-FAILED (err u2006))
(define-constant ERR-INVENTORY-UPDATE-FAILED (err u2007))
(define-constant ERR-ORDER-CREATE-FAILED (err u2008))

;; Order error codes
(define-constant ERR-ORDER-NOT-FOUND (err u3000))
(define-constant ERR-INVALID-ORDER-STATUS (err u3001))
(define-constant ERR-INSUFFICIENT-INVENTORY (err u3002))
(define-constant ERR-INVALID-QUANTITY (err u3003))
(define-constant ERR-PLACE-ORDER-FAILED (err u3004))
(define-constant ORDER-STATUS-PENDING "PENDING")
(define-constant ORDER-STATUS-CANCELLED "CANCELLED")
(define-constant ORDER-STATUS-COMPLETED "COMPLETED")
(define-constant ERR-CANCEL-ORDER-FAILED (err u3005))

;; Input validation error codes
(define-constant ERR-INVALID-INPUT (err u4000))
(define-constant ERR-EMPTY-STRING (err u4001))

;; Log error codes
(define-constant ERR-LOG-VALIDATION-FAILED (err u5000))
(define-constant ERR-LOG-STORE-UPDATE-FAILED (err u5001))
(define-constant ERR-ORDER-PARAM-VALIDATION-FAILED (err u5007))
(define-constant ERR-MANAGER-ADD-FAILED (err u5008))
(define-constant ERR-MANAGER-REMOVE-FAILED (err u5009))

;; NFT error codes
(define-constant ERR-NFT-NOT-ENABLED (err u6000))
(define-constant ERR-NFT-NOT-WHITELISTED (err u6001))
(define-constant ERR-NFT-MINT-FAILED (err u6005))
(define-constant ERR-INVALID-CONTRACT (err u6009))
(define-constant ERR-NOT-TOKEN-OWNER (err u6010))
(define-constant ERR-INVALID-TOKEN (err u6011))
(define-constant ERR-NFT-CONTRACT-UPDATE (err u6013))
(define-constant ERR-NFT-NOT-FOUND (err u6016))
(define-constant ERR-INVALID-URI (err u6017))
(define-constant ERR-INVALID-URI-FORMAT (err u6019))
(define-constant ERR-MINT-NFT-ORDER-FAILED (err u6020))
(define-constant ERR-NFT-DISABLE-FAILED (err u6021))
(define-constant ERR-NFT-CONFIG-SET-FAILED (err u6022))
(define-constant ERR-MINT-NFT-FAILED (err u6023))
(define-constant ERR-NFT-TOKEN-NOT-FOUND (err u6024))

;; Discount error codes
(define-constant ERR-DISCOUNT-NOT-FOUND (err u7000))
(define-constant ERR-INVALID-DISCOUNT (err u7002))
(define-constant ERR-INVALID-DISCOUNT-ID (err u7003))
(define-constant ERR-DISCOUNT-ADD-FAILED (err u7005))
(define-constant ERR-DISCOUNT-UPDATE-FAILED (err u7006))
(define-constant ERR-DISCOUNT-DEACTIVATE-FAILED (err u7007))

;; Buyer error codes
(define-constant ERR-INVALID-BUYER (err u403))
(define-constant ERR-UNAUTHORIZED-BUYER (err u409))

;; Payment error codes (for external payment-hub integration)
(define-constant ERR-PAYMENT-FAILED (err u8000))
(define-constant ERR-REFUND-FAILED (err u8001))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u8002))


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

;; Token URI storage (256 chars to match nft-trait)
(define-map token-uris uint (string-ascii 256))

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
    updated-at: uint
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
    token-uri: (optional (string-ascii 256)),
    enabled: bool
})

;; Product Discounts
(define-map product-discounts uint uint)


;; ========== PRIVATE FUNCTIONS ==========
;; ========== List Management Functions ==========
(define-private (add-to-order-list (id uint))
    (let ((current-list (var-get order-ids)))
        (begin
            (asserts! (< (len current-list) u200) ERR-LIST-FULL)
            (var-set order-ids (unwrap-panic (as-max-len? (append current-list id) u200)))
            (ok true))))

;; ========== List Functions ==========
(define-private (is-product-active (id uint))
    (match (map-get? products id)
        product (get active product)
        false))

(define-private (fold-product (id uint) (result (list 200 {id: uint, price: uint, name: (string-ascii 50)})))
    (match (map-get? products id)
        product (if (get active product)
            (match (as-max-len? (append result {
                id: id,
                price: (get price product),
                name: (get name product)
            }) u200)
                success success
                result)
            result)
        result))

;; ========== Authorization Functions ==========
(define-private (is-owner)
    (is-eq tx-sender contract-owner))

(define-private (validate-principal (principal principal))
    (and 
        (not (is-eq principal 'SP000000000000000000002Q6VF78))
        (not (is-eq principal (as-contract tx-sender)))
        (not (is-eq principal contract-owner))
    ))

(define-private (is-manager)
    (default-to false (map-get? managers tx-sender)))

(define-private (can-manage)
    (or (is-owner) (is-manager)))

;; ========== Input Validation Functions ==========
(define-private (validate-price (price uint))
    (and 
        (> price u0)  ;; Price must be greater than 0
        (< price u1000000000000)  ;; Add reasonable upper limit, e.g. 1 trillion
    ))

(define-private (validate-string-not-empty (value (string-ascii 50)))
    (not (is-eq value "")))

(define-private (validate-quantity (quantity uint))
    (and 
        (> quantity u0)
        (<= quantity u1000))) ;; Set reasonable upper limit

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

(define-private (validate-optional-string (value (optional (string-ascii 200))))
    (match value
        desc (validate-string-length-200 desc)
        true))

(define-private (validate-token-id (token-id uint))
    (and 
        (> token-id u0)
        (<= token-id (var-get last-token-id))
        (is-some (nft-get-owner? boom-nft token-id))))

(define-private (validate-product-id (id uint))
    (and 
        (< id (var-get product-nonce))
        (get active (default-to 
            {active: false} 
            (map-get? products id)))))

(define-private (validate-description (description (optional (string-ascii 200))))
    (match description
        desc (and (not (is-eq desc ""))
                  (<= (len desc) u200))
        true))

;; ========== Enhanced Order Processing ==========
(define-private (apply-discount (price uint) (discount-id uint))
    (match (map-get? discounts discount-id)
        discount (let (
            (discount-amount (get amount discount))
            (current-block block-height)
        )
        (if (and 
            (get active discount)
            (>= current-block (get start-block discount))
            (<= current-block (get end-block discount)))
            (let ((discount-value (/ (* price discount-amount) u100)))
                (- price discount-value))
            price))
        price))

(define-private (validate-discount-id (discount-id uint))
    (and 
        (< discount-id (var-get discount-nonce))
        (is-some (map-get? discounts discount-id))))

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
            (ok true))))

;; ========== Order Management ==========
(define-private (create-order (order-id uint) (product-id uint) (quantity uint) (buyer principal))
    (begin
        (asserts! (validate-id order-id) ERR-INVALID-ID)
        (asserts! (validate-product-id product-id) ERR-INVALID-ID)
        (asserts! (validate-quantity quantity) ERR-INVALID-QUANTITY)
        (asserts! (validate-principal buyer) ERR-INVALID-PRINCIPAL)
        
        (let ((product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND)))
            (begin
                (unwrap! (add-log "validate" "Order parameters validated") ERR-ORDER-PARAM-VALIDATION-FAILED)
                
                (map-set orders order-id {
                    id: order-id,
                    product-id: product-id,
                    quantity: quantity,
                    buyer: buyer,
                    status: ORDER-STATUS-PENDING,
                    created-at: block-height,
                    updated-at: block-height
                })
                
                (try! (add-to-order-list order-id))
                (unwrap! (add-log "create-order" "Order created") ERR-ORDER-CREATE-FAILED)
                (ok true)))))

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

(define-private (mint-nft (recipient principal))
    (let ((token-id (+ (var-get last-token-id) u1)))
        (begin
            (try! (nft-mint? boom-nft token-id recipient))
            (var-set last-token-id token-id)
            (ok token-id))))

(define-private (validate-uri-format (uri (string-ascii 256)))
    (let ((uri-len (len uri)))
        (and 
            (not (is-eq uri ""))  ;; not empty
            (>= uri-len u7)       ;; min length check
            (is-eq (slice? uri u0 u7) (some "ipfs://"))  ;; starts with ipfs://
            (<= uri-len u256)     ;; max length check
            (> uri-len u7))))  

;; ========== PUBLIC FUNCTIONS ==========
;; ========== Store Management ==========
(define-public (update-store-info 
        (name (string-ascii 50)) 
        (description (string-ascii 200)) 
        (logo (string-ascii 100)) 
        (banner (string-ascii 100)))
    (begin
        ;; Authorization check
        (asserts! (is-owner) ERR-OWNER-ONLY)
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
        
        ;; Emit event for chainhooks
        (print {event: "store-updated", name: name, owner: tx-sender})
        
        ;; Log the update
        (unwrap! (add-log "update-store" "Store information updated") ERR-LOG-STORE-UPDATE-FAILED)
        
        (ok true)))

;; ========== Role Management ==========
(define-public (add-manager (manager principal))
  (begin
    (asserts! (is-owner) ERR-NOT-AUTHORIZED)
    (asserts! (validate-principal manager) ERR-INVALID-PRINCIPAL)
    (unwrap! (add-log "validate" "Manager validated") ERR-MANAGER-VALIDATION-FAILED)
    (map-set managers manager true)
    ;; Emit event for chainhooks
    (print {event: "manager-added", manager: manager, added-by: tx-sender})
    (unwrap! (add-log "add-manager" "Manager added") ERR-MANAGER-ADD-FAILED)
    (ok true)))


(define-public (remove-manager (manager principal))
    (begin
        (asserts! (is-owner) ERR-NOT-AUTHORIZED)
        (asserts! (default-to false (map-get? managers manager)) ERR-NOT-FOUND)
        (map-delete managers manager)
        ;; Emit event for chainhooks
        (print {event: "manager-removed", manager: manager, removed-by: tx-sender})
        (unwrap! (add-log "remove-manager" "Manager removed") ERR-MANAGER-REMOVE-FAILED)
        (ok true)))

;; ========== Product Management ==========
(define-public (add-product (id uint) (price uint) (name (string-ascii 50)) (description (optional (string-ascii 200))))
    (begin
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        (asserts! (validate-price price) ERR-INVALID-PRICE)
        (asserts! (validate-string-not-empty name) ERR-EMPTY-STRING)
        
        ;; Check if product with ID already exists
        (asserts! (is-none (map-get? products id)) ERR-PRODUCT-ADD-FAILED)
        
        ;; Validate description
        (asserts! (validate-description description) ERR-INVALID-INPUT)
        
        ;; Update nonce if needed
        (if (>= id (var-get product-nonce))
            (var-set product-nonce (+ id u1))
            true)
        
        ;; Add product with validated description
        (map-set products id {
            name: name,
            price: price,
            description: description,
            active: true,
            inventory: u100,
            created-at: block-height,
            updated-at: block-height
        })
        
        ;; Add to product list
        (try! (add-to-product-list id))
        
        ;; Emit event for chainhooks
        (print {event: "product-added", product-id: id, name: name, price: price, added-by: tx-sender})
        
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
            ;; Emit event for chainhooks
            (print {event: "product-updated", product-id: id, name: name, price: price, updated-by: tx-sender})
            (unwrap! (add-log "update-product" "Product updated") ERR-PRODUCT-UPDATE-FAILED)
            (ok true))))

(define-public (remove-product (id uint))
    (let ((existing-product (unwrap! (map-get? products id) ERR-PRODUCT-NOT-FOUND)))
        (begin
            (asserts! (can-manage) ERR-NOT-AUTHORIZED)
            (asserts! (validate-id id) ERR-INVALID-ID)
            
            ;; Update product status
            (map-set products id (merge existing-product {
                active: false,
                updated-at: block-height
            }))
            
            ;; Emit event for chainhooks
            (print {event: "product-removed", product-id: id, removed-by: tx-sender})
            
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
            
            ;; Emit event for chainhooks
            (print {event: "inventory-updated", product-id: id, quantity: quantity, updated-by: tx-sender})
            
            ;; Log the update
            (unwrap! (add-log "update-inventory" "Inventory updated") ERR-INVENTORY-UPDATE-FAILED)
            (ok true))))

(define-public (place-order (product-id uint) (quantity uint) (buyer principal))
    (let (
        (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
        (order-id (var-get order-nonce))
        (current-block block-height)
        (base-price (get price product))
        (discount-id-opt (map-get? product-discounts product-id))
        (final-price (match discount-id-opt
            discount-id (apply-discount base-price discount-id)
            base-price))
        (total-amount (* final-price quantity))
    )
    (begin
        ;; First validate the product exists and is active
        (asserts! (get active product) ERR-PRODUCT-INACTIVE)
        ;; Then validate other inputs
        (asserts! (validate-id product-id) ERR-INVALID-ID)
        ;; Use validate-quantity for both lower and upper bound check
        (asserts! (validate-quantity quantity) ERR-INVALID-QUANTITY)
        ;; Validate inventory
        (asserts! (>= (get inventory product) quantity) ERR-INSUFFICIENT-INVENTORY)
        ;; Validate buyer principal
        (asserts! (validate-principal buyer) ERR-INVALID-BUYER)
        ;; Validate tx-sender is buyer
        (asserts! (is-eq tx-sender buyer) ERR-UNAUTHORIZED-BUYER)
        
        ;; NOTE: Payment is handled externally via boom-payment-hub
        ;; This contract only manages order state
        
        ;; Store order
        (map-set orders order-id {
            id: order-id,
            product-id: product-id,
            quantity: quantity,
            buyer: buyer,
            status: ORDER-STATUS-PENDING,
            created-at: current-block,
            updated-at: current-block
        })
        
        ;; Update order counter and list
        (var-set order-nonce (+ order-id u1))
        (try! (add-to-order-list order-id))
        
        ;; Update inventory
        (map-set products product-id (merge product {
            inventory: (- (get inventory product) quantity),
            updated-at: current-block
        }))
        
        ;; Emit event for chainhooks (payment-hub integration)
        (print {
            event: "order-placed",
            order-id: order-id,
            product-id: product-id,
            quantity: quantity,
            buyer: buyer,
            total-amount: total-amount,
            block-height: current-block
        })
        
        (unwrap! (add-log "place-order" "Order placed") ERR-PLACE-ORDER-FAILED)
        (ok true))))

(define-public (mint-nft-for-order (order-id uint))
    (let (
        (order (unwrap! (map-get? orders order-id) ERR-ORDER-NOT-FOUND))
        (product-id (get product-id order))
        (buyer (get buyer order))
        (nft-config (unwrap! (map-get? product-nfts product-id) ERR-NFT-NOT-FOUND))
    )
    (begin
        ;; Verify NFT is enabled for this product
        (asserts! (get enabled nft-config) ERR-NFT-NOT-ENABLED)
        ;; Verify order status is PENDING
        (asserts! (is-eq (get status order) ORDER-STATUS-PENDING) ERR-INVALID-ORDER-STATUS)
        ;; Only owner can mint NFTs
        (asserts! (is-owner) ERR-OWNER-ONLY)
        
        ;; Mint NFT
        (let ((token-id (try! (mint-nft buyer))))
            ;; Set token URI if provided
            (match (get token-uri nft-config)
                uri (map-set token-uris token-id uri)
                true)
            
            ;; Update order status
            (map-set orders order-id (merge order {
                status: ORDER-STATUS-COMPLETED,
                updated-at: block-height
            }))
            
            ;; Emit event for chainhooks
            (print {
                event: "nft-minted-for-order",
                order-id: order-id,
                token-id: token-id,
                buyer: buyer,
                product-id: product-id
            })
            
            ;; Log the minting
            (unwrap! (add-log "mint-nft" "NFT minted for order") ERR-MINT-NFT-FAILED)
            
            (ok (some buyer))))))

(define-public (cancel-order (order-id uint))
    (let (
        (order (unwrap! (map-get? orders order-id) ERR-NOT-FOUND))
        (current-block block-height)
        (product-id (get product-id order))
        (quantity (get quantity order))
        (buyer (get buyer order))
        (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
    )
    (begin
        ;; Authorization check
        (asserts! (or 
            (is-eq tx-sender buyer)
            (can-manage)
        ) ERR-NOT-AUTHORIZED)
        
        ;; Status validation - can only cancel PENDING orders
        (asserts! (is-eq (get status order) ORDER-STATUS-PENDING) ERR-INVALID-ORDER-STATUS)
        
        ;; NOTE: Refunds are handled externally via boom-payment-hub
        ;; This contract only manages order state
        
        ;; Restore inventory
        (map-set products product-id (merge product {
            inventory: (+ (get inventory product) quantity),
            updated-at: current-block
        }))
        
        ;; Update order status with timestamps
        (map-set orders order-id (merge order {
            status: ORDER-STATUS-CANCELLED,
            updated-at: current-block
        }))
        
        ;; Emit event for chainhooks (payment-hub refund integration)
        (print {
            event: "order-cancelled",
            order-id: order-id,
            product-id: product-id,
            quantity: quantity,
            buyer: buyer,
            cancelled-by: tx-sender
        })
        
        ;; Log the cancellation
        (unwrap! (add-log "cancel-order" "Order cancelled") ERR-CANCEL-ORDER-FAILED)
        
        (ok true))))

;; ========== Discount Management ==========
(define-public (add-discount (product-id uint) (amount uint) (start-block uint) (end-block uint))
    (begin
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? products product-id)) ERR-PRODUCT-NOT-FOUND)
        (asserts! (and (> amount u0) (< amount u100)) ERR-INVALID-DISCOUNT)
        (asserts! (>= end-block start-block) ERR-INVALID-DISCOUNT)
        
        (let ((discount-id (var-get discount-nonce)))
            ;; Set the discount
            (map-set discounts discount-id {
                id: discount-id,
                product-id: product-id,
                amount: amount,
                start-block: start-block,
                end-block: end-block,
                active: true,
                created-at: block-height,
                updated-at: block-height
            })
            ;; Map product-id to discount-id
            (map-set product-discounts product-id discount-id)
            ;; Add to discount IDs list
            (var-set discount-ids (unwrap! (as-max-len? (append (var-get discount-ids) discount-id) u200) ERR-LIST-FULL))
            ;; Increment nonce
            (var-set discount-nonce (+ discount-id u1))
            ;; Emit event for chainhooks
            (print {event: "discount-added", discount-id: discount-id, product-id: product-id, amount: amount, start-block: start-block, end-block: end-block})
            ;; Log addition
            (unwrap! (add-log "add-discount" "Discount added") ERR-DISCOUNT-ADD-FAILED)
            (ok discount-id))))

(define-public (update-discount (discount-id uint) (amount uint) (end-block uint))
    (begin
        ;; Authorization check
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        ;; Validate discount ID
        (asserts! (validate-discount-id discount-id) ERR-INVALID-DISCOUNT-ID)
        ;; Validate amount
        (asserts! (< amount u100) ERR-INVALID-DISCOUNT)
        ;; Validate end block
        (asserts! (>= end-block block-height) ERR-INVALID-DISCOUNT)
        
        ;; Get existing discount after validation
        (let ((existing-discount (unwrap! (map-get? discounts discount-id) ERR-DISCOUNT-NOT-FOUND)))
            ;; Create updated discount data
            (let ((updated-discount (merge existing-discount {
                    amount: amount,
                    end-block: end-block,
                    updated-at: block-height
                })))
                ;; Update discount
                (map-set discounts discount-id updated-discount)
                ;; Emit event for chainhooks
                (print {event: "discount-updated", discount-id: discount-id, amount: amount, end-block: end-block})
                ;; Log update
                (unwrap! (add-log "update-discount" "Discount updated") ERR-DISCOUNT-UPDATE-FAILED)
                (ok true)))))

(define-public (deactivate-discount (product-id uint))
    (begin
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        (let ((discount-id (unwrap! (map-get? product-discounts product-id) ERR-DISCOUNT-NOT-FOUND)))
            (let ((discount (unwrap! (map-get? discounts discount-id) ERR-DISCOUNT-NOT-FOUND)))
                (map-set discounts discount-id (merge discount {
                        active: false,
                        updated-at: block-height
                    }))
                ;; Remove product-discount mapping
                (map-delete product-discounts product-id)
                ;; Emit event for chainhooks
                (print {event: "discount-deactivated", discount-id: discount-id, product-id: product-id})
                (unwrap! (add-log "deactivate-discount" "Discount deactivated") ERR-DISCOUNT-DEACTIVATE-FAILED)
                (ok true)))))

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
        ;; Emit event for chainhooks
        (print {event: "nft-transfer", token-id: token-id, sender: sender, recipient: recipient})
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
            ;; Emit event for chainhooks
            (print {event: "nft-minted", token-id: token-id, recipient: recipient, minted-by: tx-sender})
            ;; Log the mint
            (unwrap! (add-log "mint-nft" "NFT minted successfully") ERR-NFT-MINT-FAILED)
            (ok token-id))))

;; NFT URI management
(define-public (set-token-uri (token-id uint) (uri (string-ascii 256)))
    (begin
        ;; Authorization check
        (asserts! (is-owner) ERR-OWNER-ONLY)
        ;; Validate token exists
        (asserts! (is-some (nft-get-owner? boom-nft token-id)) ERR-NFT-TOKEN-NOT-FOUND)
        ;; Validate URI format
        (asserts! (validate-uri-format uri) ERR-INVALID-URI)
        ;; Set the URI
        (map-set token-uris token-id uri)
        ;; Log the update
        (print {event: "set-token-uri", token-id: token-id, uri: uri})
        (ok true)))

;; NFT contract management
(define-public (set-nft-contract (contract principal) (enabled bool))
    (begin
        (asserts! (is-owner) ERR-OWNER-ONLY)
        ;; Validate contract principal
        (asserts! (not (is-eq contract 'SP000000000000000000002Q6VF78)) ERR-INVALID-CONTRACT)
        (asserts! (not (is-eq contract (as-contract tx-sender))) ERR-INVALID-CONTRACT)
        (asserts! (not (is-eq contract contract-owner)) ERR-INVALID-CONTRACT)
        
        ;; Set contract status after validation
        (map-set nft-contracts contract enabled)
        ;; Emit event for chainhooks
        (print {event: "nft-contract-updated", contract: contract, enabled: enabled})
        (unwrap! (add-log "set-nft-contract" "NFT contract updated") ERR-NFT-CONTRACT-UPDATE)
        (ok true)))

(define-public (set-product-nft (product-id uint) (nft-contract principal) (token-uri (optional (string-ascii 256))))
    (begin
        (asserts! (is-owner) ERR-OWNER-ONLY)
        (asserts! (validate-id product-id) ERR-INVALID-ID)
        (asserts! (default-to false (map-get? nft-contracts nft-contract)) ERR-NFT-NOT-WHITELISTED)
        
        ;; Validate URI if provided
        (match token-uri
            uri (asserts! (validate-uri-format uri) ERR-INVALID-URI-FORMAT)
            true)
        
        ;; Validate contract principal
        (asserts! (not (is-eq nft-contract 'SP000000000000000000002Q6VF78)) ERR-INVALID-CONTRACT)
        (asserts! (not (is-eq nft-contract (as-contract tx-sender))) ERR-INVALID-CONTRACT)
        (asserts! (not (is-eq nft-contract contract-owner)) ERR-INVALID-CONTRACT)
        
        ;; Create validated config tuple
        (let ((validated-config {
                nft-contract: nft-contract,
                token-uri: (match token-uri 
                    uri (if (validate-uri-format uri) 
                            (some uri)
                            none)
                    none),
                enabled: true
            }))
            
            ;; Set NFT config after all validations pass
            (map-set product-nfts product-id validated-config)
            
            ;; Emit event for chainhooks
            (print {event: "product-nft-set", product-id: product-id, nft-contract: nft-contract})
            
            (unwrap! (add-log "set-product-nft" "NFT config set for product") ERR-NFT-CONFIG-SET-FAILED)
            (ok true))))

(define-public (disable-product-nft (product-id uint))
    (begin
        (asserts! (can-manage) ERR-NOT-AUTHORIZED)
        (asserts! (validate-id product-id) ERR-INVALID-ID)
        
        (match (map-get? product-nfts product-id)
            config (begin
                (map-set product-nfts product-id (merge config {enabled: false}))
                ;; Emit event for chainhooks
                (print {event: "product-nft-disabled", product-id: product-id})
                (unwrap! (add-log "disable-nft" "NFT disabled for product") ERR-NFT-DISABLE-FAILED)
                (ok true))
            ERR-NFT-MINT-FAILED)))

(define-private (add-to-product-list (id uint))
    (let ((current-list (var-get product-ids)))
        (begin 
            (asserts! (< (len current-list) u200) ERR-LIST-FULL)
            (var-set product-ids (unwrap-panic (as-max-len? (append current-list id) u200)))
            (ok true))))


;; ========== READ-ONLY FUNCTIONS ==========
(define-read-only (list-products)
    (ok (fold fold-product 
        (filter is-product-active (var-get product-ids))
        (list))))

(define-read-only (list-orders)
    (ok (fold fold-order (var-get order-ids) (list))))

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

(define-read-only (get-order-details (id uint))
    (match (map-get? orders id)
        order (ok {
            id: (get id order),
            product-id: (get product-id order),
            quantity: (get quantity order),
            buyer: (get buyer order),
            status: (get status order),
            created-at: (get created-at order),
            updated-at: (get updated-at order)
        })
        ERR-ORDER-NOT-FOUND))

(define-read-only (get-discount (discount-id uint))
    (ok (map-get? discounts discount-id)))

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? boom-nft token-id)))

(define-read-only (get-product-nft (product-id uint))
    (begin
        (asserts! (validate-product-id product-id) ERR-INVALID-ID)
        (ok (unwrap! (map-get? product-nfts product-id) ERR-NFT-NOT-FOUND))))

(define-read-only (is-nft-enabled (product-id uint))
    (begin
        (asserts! (validate-product-id product-id) ERR-INVALID-ID)
        (ok (default-to false (get enabled (map-get? product-nfts product-id))))))

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id)))

(define-read-only (get-token-uri (token-id uint))
    (begin
        (asserts! (validate-token-id token-id) ERR-INVALID-TOKEN)
        (ok (map-get? token-uris token-id))))

(define-read-only (get-last-log)
    (let ((current-nonce (var-get log-nonce)))
        (if (is-eq current-nonce u0)
            ERR-NOT-FOUND
            (let ((last-id (- current-nonce u1)))
                (ok (unwrap! (map-get? logs last-id) ERR-NOT-FOUND))))))

(define-read-only (get-discounted-price (product-id uint))
    (let (
        ;; Get product details
        (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
        (price (get price product))
        (discount-id (map-get? product-discounts product-id))
    )
    (match discount-id
        id (let ((discount (unwrap! (map-get? discounts id) ERR-DISCOUNT-NOT-FOUND)))
            (if (and 
                (get active discount)
                (>= block-height (get start-block discount))
                (<= block-height (get end-block discount)))
                ;; Apply discount if active and within period
                (let (
                    (discount-amount (get amount discount))
                    (discount-value (/ (* price discount-amount) u100))
                )
                (ok (- price discount-value)))
                ;; Return original price if discount not applicable
                (ok price)))
        ;; Return original price if no discount exists
        (ok price))))