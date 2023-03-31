{- Typing rules of the cast calculus -}

open import Common.Types

module CC2.CCTyping (Cast_⇒_ : Type → Type → Set) where

open import Data.Nat
open import Data.Product renaming (_,_ to ⟨_,_⟩)
open import Data.Maybe
open import Data.List
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

open import Syntax
open import Common.Utils
open import Common.Types
open import Memory.HeapContext
open import CC2.CCSyntax Cast_⇒_

infix 4 _;_;_;_⊢_⦂_

data _;_;_;_⊢_⦂_ : Context → HeapContext → Label → StaticLabel → Term → Type → Set where

  ⊢const : ∀ {Γ Σ gc pc ι} {k : rep ι} {ℓ}
      -------------------------------------------- CCConst
    → Γ ; Σ ; gc ; pc ⊢ $ k of ℓ ⦂ ` ι of l ℓ

  ⊢addr : ∀ {Γ Σ gc pc n T ℓ ℓ̂}
    → lookup-Σ Σ (a⟦ ℓ̂ ⟧ n) ≡ just T
      ------------------------------------------------ CCAddr
    → Γ ; Σ ; gc ; pc ⊢ addr (a⟦ ℓ̂ ⟧ n) of ℓ ⦂ Ref (T of l ℓ̂) of l ℓ

  ⊢var : ∀ {Γ Σ gc pc A x}
    → Γ ∋ x ⦂ A
      ----------------------------- CCVar
    → Γ ; Σ ; gc ; pc ⊢ ` x ⦂ A

  ⊢lam : ∀ {Γ Σ gc pc pc′ A B N ℓ}
    → (∀ {pc} → A ∷ Γ ; Σ ; l pc′ ; pc ⊢ N ⦂ B)
      ------------------------------------------------------------------- CCLam
    → Γ ; Σ ; gc ; pc ⊢ ƛ⟦ pc′ ⟧ A ˙ N of ℓ ⦂ ⟦ l pc′ ⟧ A ⇒ B of l ℓ

  ⊢app : ∀ {Γ Σ pc pc′ A B L M ℓ ℓᶜ}
    → Γ ; Σ ; l pc′ ; pc ⊢ L ⦂ ⟦ l ℓᶜ ⟧ A ⇒ B of l ℓ
    → Γ ; Σ ; l pc′ ; pc ⊢ M ⦂ A
    → pc′ ≼ ℓᶜ → ℓ ≼ ℓᶜ
      --------------------------------------- CCAppStatic
    → Γ ; Σ ; l pc′ ; pc ⊢ app L M ⦂ stamp B (l ℓ)

  ⊢app? : ∀ {Γ Σ gc pc A B L M p}
    → Γ ; Σ ; gc ; pc ⊢ L ⦂ ⟦ ⋆ ⟧ A ⇒ B of ⋆
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ A
      --------------------------------------- CCAppUnchecked
    → Γ ; Σ ; gc ; pc ⊢ app? L M p ⦂ stamp B ⋆

  ⊢app✓ : ∀ {Γ Σ gc pc A B L M ℓ ℓᶜ}
    → Γ ; Σ ; gc ; pc ⊢ L ⦂ ⟦ l ℓᶜ ⟧ A ⇒ B of l ℓ
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ A
    → pc ≼ ℓᶜ → ℓ ≼ ℓᶜ
      --------------------------------------- CCAppChecked
    → Γ ; Σ ; gc ; pc ⊢ app✓ L M ⦂ stamp B (l ℓ)

  ⊢if : ∀ {Γ Σ pc pc′ A L M N ℓ}
    → Γ ; Σ ; l pc′ ; pc ⊢ L ⦂ ` Bool of l ℓ
    → (∀ {pc} → Γ ; Σ ; l (pc′ ⋎ ℓ) ; pc ⊢ M ⦂ A)
    → (∀ {pc} → Γ ; Σ ; l (pc′ ⋎ ℓ) ; pc ⊢ N ⦂ A)
      --------------------------------------------------------- CCIf
    → Γ ; Σ ; l pc′ ; pc ⊢ if L A M N ⦂ stamp A (l ℓ)

  ⊢if⋆ : ∀ {Γ Σ gc pc A L M N}
    → Γ ; Σ ; gc ; pc ⊢ L ⦂ ` Bool of ⋆
    → (∀ {pc} → Γ ; Σ ; ⋆ ; pc ⊢ M ⦂ A)
    → (∀ {pc} → Γ ; Σ ; ⋆ ; pc ⊢ N ⦂ A)
      --------------------------------------------------------- CCIf⋆
    → Γ ; Σ ; gc ; pc ⊢ if⋆ L A M N ⦂ stamp A ⋆

  ⊢let : ∀ {Γ Σ gc pc M N A B}
    → Γ       ; Σ ; gc ; pc ⊢ M ⦂ A
    → (∀ {pc} → A ∷ Γ ; Σ ; gc ; pc ⊢ N ⦂ B)
      ----------------------------------- CCLet
    → Γ ; Σ ; gc ; pc ⊢ `let M N ⦂ B

  ⊢ref : ∀ {Γ Σ pc pc′ M T ℓ}
    → Γ ; Σ ; l pc′ ; pc ⊢ M ⦂ T of l ℓ
    → pc′ ≼ ℓ
      ---------------------------------------------------------- CCRefStatic
    → Γ ; Σ ; l pc′ ; pc ⊢ ref⟦ ℓ ⟧ M ⦂ Ref (T of l ℓ) of l low

  ⊢ref? : ∀ {Γ Σ gc pc M T ℓ p}
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ T of l ℓ
      ---------------------------------------------------------- CCRefUnchecked
    → Γ ; Σ ; gc ; pc ⊢ ref?⟦ ℓ ⟧ M p ⦂ Ref (T of l ℓ) of l low

  ⊢ref✓ : ∀ {Γ Σ gc pc M T ℓ}
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ T of l ℓ
    → pc ≼ ℓ
      ---------------------------------------------------------- CCRefChecked
    → Γ ; Σ ; gc ; pc ⊢ ref✓⟦ ℓ ⟧ M ⦂ Ref (T of l ℓ) of l low

  ⊢deref : ∀ {Γ Σ gc pc M A g}
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ Ref A of g
      ------------------------------------- CCDeref
    → Γ ; Σ ; gc ; pc ⊢ ! M ⦂ stamp A g

  ⊢assign : ∀ {Γ Σ pc pc′ L M T ℓ ℓ̂}
    → Γ ; Σ ; l pc′ ; pc ⊢ L ⦂ Ref (T of l ℓ̂) of l ℓ
    → Γ ; Σ ; l pc′ ; pc ⊢ M ⦂ T of l ℓ̂
    → ℓ ≼ ℓ̂ → pc′ ≼ ℓ̂
      --------------------------------------------- CCAssignStatic
    → Γ ; Σ ; l pc′ ; pc ⊢ assign L M ⦂ ` Unit of l low

  ⊢assign? : ∀ {Γ Σ gc pc L M T p}
    → Γ ; Σ ; gc ; pc ⊢ L ⦂ Ref (T of ⋆) of ⋆
    → (∀ {pc} → Γ ; Σ ; gc ; pc ⊢ M ⦂ T of ⋆)
      --------------------------------------------- CCAssignUnchecked
    → Γ ; Σ ; gc ; pc ⊢ assign? L M p ⦂ ` Unit of l low

  ⊢assign✓ : ∀ {Γ Σ gc pc L M T ℓ ℓ̂}
    → Γ ; Σ ; gc ; pc ⊢ L ⦂ Ref (T of l ℓ̂) of l ℓ
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ T of l ℓ̂
    → ℓ ≼ ℓ̂ → pc ≼ ℓ̂
      --------------------------------------------- CCAssignChecked
    → Γ ; Σ ; gc ; pc ⊢ assign✓ L M ⦂ ` Unit of l low

  ⊢prot : ∀ {Γ Σ gc pc A M g ℓ}
    → Γ ; Σ ; g ⋎̃ l ℓ ; pc ⋎ ℓ ⊢ M ⦂ A
    → l pc ~ₗ g
      ----------------------------------------------- CCProt
    → Γ ; Σ ; gc ; pc ⊢ prot g ℓ M ⦂ stamp A (l ℓ)

  ⊢cast : ∀ {Γ Σ gc pc A B M} {c : Cast A ⇒ B}
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ A
      ----------------------------------------- CCCast
    → Γ ; Σ ; gc ; pc ⊢ M ⟨ c ⟩ ⦂ B

  ⊢err : ∀ {Γ Σ gc pc A e p}
      ------------------------------------ CCError
    → Γ ; Σ ; gc ; pc ⊢ blame e p ⦂ A

  ⊢sub : ∀ {Γ Σ gc pc A B M}
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ A
    → A <: B
      -------------------------- CCSub
    → Γ ; Σ ; gc ; pc ⊢ M ⦂ B

  ⊢sub-pc : ∀ {Γ Σ gc gc′ pc A M}
    → Γ ; Σ ; gc′ ; pc ⊢ M ⦂ A
    → gc <:ₗ gc′
      -------------------------- CCSubPC
    → Γ ; Σ ; gc  ; pc ⊢ M ⦂ A