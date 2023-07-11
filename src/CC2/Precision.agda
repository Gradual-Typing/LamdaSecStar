{- Precision relation of CC2 -}

open import Common.Types

module CC2.Precision where

open import Data.Nat
open import Data.Unit using (⊤; tt)
open import Data.Bool using (true; false) renaming (Bool to 𝔹)
open import Data.List
open import Data.Product using (_×_; ∃-syntax; proj₁; proj₂) renaming (_,_ to ⟨_,_⟩)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Maybe
open import Relation.Nullary using (¬_; Dec; yes; no)
open import Relation.Nullary.Negation using (contradiction)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; trans; subst; subst₂; sym)
open import Function using (case_of_)

open import Syntax
open import Common.Utils
open import Memory.HeapContext
open import CC2.Statics


data _⊑*_ : (Γ Γ′ : Context) → Set where

  ⊑*-∅ : [] ⊑* []

  ⊑*-∷ : ∀ {Γ Γ′ A A′} → A ⊑ A′ → Γ ⊑* Γ′ → (A ∷ Γ) ⊑* (A′ ∷ Γ′)


⊑*→⊑ : ∀ {Γ Γ′ A A′ x} → Γ ⊑* Γ′ → Γ ∋ x ⦂ A → Γ′ ∋ x ⦂ A′ → A ⊑ A′
⊑*→⊑ {x = 0}     (⊑*-∷ A⊑A′ Γ⊑Γ′) refl refl = A⊑A′
⊑*→⊑ {x = suc x} (⊑*-∷ A⊑A′ Γ⊑Γ′) Γ∋x  Γ′∋x = ⊑*→⊑ Γ⊑Γ′ Γ∋x Γ′∋x


data _⊑ₕ_ : (Σ Σ′ : HalfHeapContext) → Set where

  ⊑-∅ : [] ⊑ₕ []

  ⊑-∷ : ∀ {Σ Σ′ T T′ n} → T ⊑ᵣ T′ → Σ ⊑ₕ Σ′ → (⟨ n , T ⟩ ∷ Σ) ⊑ₕ (⟨ n , T′ ⟩ ∷ Σ′)

_⊑ₘ_ : (Σ Σ′ : HeapContext) → Set
⟨ Σᴸ , Σᴴ ⟩ ⊑ₘ ⟨ Σᴸ′ , Σᴴ′ ⟩ = (Σᴸ ⊑ₕ Σᴸ′) × (Σᴴ ⊑ₕ Σᴴ′)

⊑ₕ→⊑ : ∀ {Σ Σ′ T T′ n}
  → Σ ⊑ₕ Σ′
  → find _≟_ Σ  n ≡ just T
  → find _≟_ Σ′ n ≡ just T′
  → T ⊑ᵣ T′
⊑ₕ→⊑ {⟨ n₀ , T ⟩ ∷ _} {⟨ n₀ , T′ ⟩ ∷ _} {n = n} (⊑-∷ T⊑T′ Σ⊑Σ′) eq eq′
  with n ≟ n₀
... | no _ = ⊑ₕ→⊑ Σ⊑Σ′ eq eq′
... | yes refl with eq | eq′
... | refl | refl = T⊑T′

⊑ₘ→⊑ : ∀ {Σ Σ′ T T′ n ℓ̂}
  → Σ ⊑ₘ Σ′
  → let a = a⟦ ℓ̂ ⟧ n in
     lookup-Σ Σ  a ≡ just T
  → lookup-Σ Σ′ a ≡ just T′
  → T ⊑ᵣ T′
⊑ₘ→⊑ {ℓ̂ = low}  ⟨ Σᴸ⊑ , _ ⟩ Σa≡T Σ′a≡T′ = ⊑ₕ→⊑ Σᴸ⊑ Σa≡T Σ′a≡T′
⊑ₘ→⊑ {ℓ̂ = high} ⟨ _ , Σᴴ⊑ ⟩ Σa≡T Σ′a≡T′ = ⊑ₕ→⊑ Σᴴ⊑ Σa≡T Σ′a≡T′


infix 4 _;_∣_;_∣_;_∣_;_⊢_⊑_⇐_⊑_

data _;_∣_;_∣_;_∣_;_⊢_⊑_⇐_⊑_ : (Γ Γ′ : Context) (Σ Σ′ : HeapContext)
  (g g′ : Label) (ℓ ℓ′ : StaticLabel) (M M′ : Term) (A A′ : Type) → Set where

  ⊑-var : ∀ {Γ Γ′ Σ Σ′ gc gc′ ℓv ℓv′ A A′ x}
    → Γ  ∋ x ⦂ A
    → Γ′ ∋ x ⦂ A′
      ---------------------------------------------------------------
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ ` x ⊑ ` x ⇐ A ⊑ A′

  ⊑-const : ∀ {Γ Γ′ Σ Σ′ gc gc′ ℓv ℓv′ ι ℓ} {k : rep ι}
      ---------------------------------------------------------
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ $ k ⊑ $ k
         ⇐ ` ι of l ℓ ⊑ ` ι of l ℓ

  ⊑-addr : ∀ {Γ Γ′ Σ Σ′ gc gc′ ℓv ℓv′} {n ℓ ℓ̂ T T′}
    → lookup-Σ Σ  (a⟦ ℓ̂ ⟧ n) ≡ just T
    → lookup-Σ Σ′ (a⟦ ℓ̂ ⟧ n) ≡ just T′
      -------------------------------------------------------------
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ addr n ⊑ addr n
         ⇐ Ref (T of l ℓ̂) of l ℓ ⊑ Ref (T′ of l ℓ̂) of l ℓ

  ⊑-lam : ∀ {Γ Γ′ Σ Σ′ gc gc′ ℓv ℓv′} {N N′} {g g′ A A′ B B′ ℓ}
    → g ⊑ₗ g′
    → A ⊑  A′
    → (∀ {ℓv ℓv′} → A ∷ Γ ; A′ ∷ Γ′ ∣ Σ ; Σ′ ∣ g ; g′ ∣ ℓv ; ℓv′ ⊢ N ⊑ N′ ⇐ B ⊑ B′)
      --------------------------------------------------------------------------------------
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ ƛ N ⊑ ƛ N′
         ⇐ ⟦ g ⟧ A ⇒ B of l ℓ ⊑ ⟦ g′ ⟧ A′ ⇒ B′ of l ℓ

  ⊑-app : ∀ {Γ Γ′ Σ Σ′ ℓc ℓv ℓv′} {L L′ M M′} {A A′ B B′ C C′ ℓ}
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ l ℓc ; l ℓc ∣ ℓv ; ℓv′ ⊢ L ⊑ L′
         ⇐ ⟦ l (ℓc ⋎ ℓ) ⟧ A ⇒ B of l ℓ ⊑ ⟦ l (ℓc ⋎ ℓ) ⟧ A′ ⇒ B′ of l ℓ
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ l ℓc ; l ℓc ∣ ℓv ; ℓv′ ⊢ M ⊑ M′ ⇐ A ⊑ A′
    → C  ≡ stamp B  (l ℓ)
    → C′ ≡ stamp B′ (l ℓ)
      -------------------------------------------------------------------------------------------
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ l ℓc ; l ℓc ∣ ℓv ; ℓv′ ⊢ app L M A B ℓ ⊑ app L′ M′ A′ B′ ℓ ⇐ C ⊑ C′

  ⊑-app! : ∀ {Γ Γ′ Σ Σ′ gc gc′ ℓv ℓv′} {L L′ M M′} {A A′ B B′ C C′}
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ L ⊑ L′
         ⇐ ⟦ ⋆ ⟧ A ⇒ B of ⋆ ⊑ ⟦ ⋆ ⟧ A′ ⇒ B′ of ⋆
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ M ⊑ M′ ⇐ A ⊑ A′
    → C  ≡ stamp B  ⋆
    → C′ ≡ stamp B′ ⋆
      -------------------------------------------------------------------------------------------
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ app! L M A B ⊑ app! L′ M′ A′ B′ ⇐ C ⊑ C′

  ⊑-app!l : ∀ {Γ Γ′ Σ Σ′ gc ℓc ℓv ℓv′} {L L′ M M′} {A A′ B B′ C C′ ℓ}
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; l ℓc ∣ ℓv ; ℓv′ ⊢ L ⊑ L′
         ⇐ ⟦ ⋆ ⟧ A ⇒ B of ⋆ ⊑ ⟦ l (ℓc ⋎ ℓ) ⟧ A′ ⇒ B′ of l ℓ
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; l ℓc ∣ ℓv ; ℓv′ ⊢ M ⊑ M′ ⇐ A ⊑ A′
    → C  ≡ stamp B     ⋆
    → C′ ≡ stamp B′ (l ℓ)
      -------------------------------------------------------------------------------------------
    → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; l ℓc ∣ ℓv ; ℓv′ ⊢ app! L M A B ⊑ app L′ M′ A′ B′ ℓ ⇐ C ⊑ C′


{- The term precision relation implies that both terms are well-typed.
   Furthermore, their types are related by type precision. -}
cc-prec-inv : ∀ {Γ Γ′ Σ Σ′ gc gc′ ℓv ℓv′} {M M′} {A A′}
  → Γ ⊑* Γ′
  → Σ ⊑ₘ Σ′
  → Γ ; Γ′ ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ M ⊑ M′ ⇐ A ⊑ A′
    -------------------------------------------------------------
  → Γ  ; Σ  ; gc  ; ℓv  ⊢ M  ⇐ A    ×
     Γ′ ; Σ′ ; gc′ ; ℓv′ ⊢ M′ ⇐ A′   ×
     A ⊑ A′
cc-prec-inv Γ⊑Γ′ _ (⊑-var Γ∋x Γ′∋x) = ⟨ ⊢var Γ∋x , ⊢var Γ′∋x , ⊑*→⊑ Γ⊑Γ′ Γ∋x Γ′∋x ⟩
cc-prec-inv _ _ ⊑-const = ⟨ ⊢const , ⊢const , ⊑-ty l⊑l ⊑-ι ⟩
cc-prec-inv _ Σ⊑Σ′ (⊑-addr {n = n} {ℓ} {ℓ̂} Σa≡T Σ′a≡T′) =
  ⟨ ⊢addr Σa≡T , ⊢addr Σ′a≡T′ , ⊑-ty l⊑l (⊑-ref (⊑-ty l⊑l (⊑ₘ→⊑ {n = n} {ℓ̂} Σ⊑Σ′ Σa≡T Σ′a≡T′))) ⟩
cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ (⊑-lam g⊑g′ A⊑A′ N⊑N′) =
  let prec* = ⊑*-∷ A⊑A′ Γ⊑Γ′ in
  ⟨ ⊢lam (proj₁        (cc-prec-inv {ℓv′ = low} prec* Σ⊑Σ′ N⊑N′))  ,
    ⊢lam (proj₁ (proj₂ (cc-prec-inv {ℓv  = low} prec* Σ⊑Σ′ N⊑N′))) ,
    ⊑-ty l⊑l (⊑-fun g⊑g′ A⊑A′ (proj₂ (proj₂ (cc-prec-inv {ℓv = low} {low} prec* Σ⊑Σ′ N⊑N′)))) ⟩
{- Application -}
cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ (⊑-app {C = C} {C′} L⊑L′ M⊑M′ eq eq′) =
  let ⟨ ⊢L , ⊢L′ , A→B⊑A′→B′ ⟩ = cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ L⊑L′ in
  let ⟨ ⊢M , ⊢M′ , _           ⟩ = cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ M⊑M′ in
  case A→B⊑A′→B′ of λ where
  (⊑-ty l⊑l (⊑-fun l⊑l A⊑A′ B⊑B′)) →
    let C⊑C′ : C ⊑ C′
        C⊑C′ = subst₂ _⊑_ (sym eq) (sym eq′) (stamp-⊑ B⊑B′ l⊑l) in
    ⟨ ⊢app ⊢L ⊢M eq , ⊢app ⊢L′ ⊢M′ eq′ , C⊑C′ ⟩
cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ (⊑-app! {C = C} {C′} L⊑L′ M⊑M′ eq eq′) =
  let ⟨ ⊢L , ⊢L′ , A→B⊑A′→B′ ⟩ = cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ L⊑L′ in
  let ⟨ ⊢M , ⊢M′ , _           ⟩ = cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ M⊑M′ in
  case A→B⊑A′→B′ of λ where
  (⊑-ty ⋆⊑ (⊑-fun ⋆⊑ A⊑A′ B⊑B′)) →
    let C⊑C′ : C ⊑ C′
        C⊑C′ = subst₂ _⊑_ (sym eq) (sym eq′) (stamp-⊑ B⊑B′ ⋆⊑) in
    ⟨ ⊢app! ⊢L ⊢M eq , ⊢app! ⊢L′ ⊢M′ eq′ , C⊑C′ ⟩
cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ (⊑-app!l {C = C} {C′} L⊑L′ M⊑M′ eq eq′) =
  let ⟨ ⊢L , ⊢L′ , A→B⊑A′→B′ ⟩ = cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ L⊑L′ in
  let ⟨ ⊢M , ⊢M′ , _           ⟩ = cc-prec-inv Γ⊑Γ′ Σ⊑Σ′ M⊑M′ in
  case A→B⊑A′→B′ of λ where
  (⊑-ty ⋆⊑ (⊑-fun ⋆⊑ A⊑A′ B⊑B′)) →
    let C⊑C′ : C ⊑ C′
        C⊑C′ = subst₂ _⊑_ (sym eq) (sym eq′) (stamp-⊑ B⊑B′ ⋆⊑) in
    ⟨ ⊢app! ⊢L ⊢M eq , ⊢app ⊢L′ ⊢M′ eq′ , C⊑C′ ⟩