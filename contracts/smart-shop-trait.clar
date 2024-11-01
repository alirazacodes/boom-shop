;; title: smart-shop-trait
;; version: 0.0.1
;; summary: Simple trait to identify smart shops
;; description: Simple trait to identify smart shops

(define-trait smart-shop-trait
  (
    ;; Product Management
    (add-product (uint uint (string-ascii 50) (optional (string-ascii 200))) (response bool uint))
    (update-product (uint uint (string-ascii 50) (optional (string-ascii 200))) (response bool uint))
    (remove-product (uint) (response bool uint))
    (get-product (uint) (response {
        id: uint,
        price: uint,
        name: (string-ascii 50),
        description: (optional (string-ascii 200))
    } uint))
    (list-products () (response (list 200 {
        id: uint,
        price: uint,
        name: (string-ascii 50)
    }) uint))

    ;; Order Processing
    (place-order (uint uint principal) (response bool uint))
    (cancel-order (uint) (response bool uint))
    (get-order (uint) (response {
        id: uint,
        product-id: uint,
        quantity: uint,
        buyer: principal,
        status: (string-ascii 20)
    } uint))
    (list-orders () (response (list 200 {
        id: uint,
        product-id: uint,
        quantity: uint,
        buyer: principal,
        status: (string-ascii 20)
    }) uint))

    ;; Inventory Management
    (update-inventory (uint uint) (response bool uint))
    (get-inventory (uint) (response uint uint))
  )
)