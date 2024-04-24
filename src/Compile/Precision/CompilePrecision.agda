module Compile.Precision.CompilePrecision where

open import Data.Nat
open import Data.List
open import Data.Product using (_×_; ∃; ∃-syntax; proj₁; proj₂) renaming (_,_ to ⟨_,_⟩)
open import Data.Maybe
open import Relation.Nullary using (¬_; Dec; yes; no)
open import Relation.Nullary.Negation using (contradiction)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; subst; sym)
open import Function using (case_of_)

open import Syntax

open import Common.Utils
open import Common.BlameLabels
open import Common.Types
open import Common.TypeBasedCast
open import Common.CoercePrecision
open import Surface2.Lang
  renaming (`_ to `ᴳ_;
            $_of_ to $ᴳ_of_)
open import Surface2.Typing
open import Surface2.Precision

open import CC2.Syntax public  renaming (Term to CCTerm)
open import CC2.Typing public
open import CC2.Precision
open import CC2.Compile


{- Here is the (lemma?) statement of "compilation preserves precision" -}
compile-pres-precision : ∀ {Γ Γ′ g g′ M M′ A A′}
  → Γ ⊑* Γ′
  → g ⊑ₗ g′
  → ⊢ M ⊑ᴳ M′
  → (⊢M  : Γ  ; g  ⊢ᴳ M  ⦂ A )
  → (⊢M′ : Γ′ ; g′ ⊢ᴳ M′ ⦂ A′)
    --------------------------------------------------------------------------------------------
  → (∀ {ℓ ℓ′} → Γ ; Γ′ ∣ ∅ ; ∅ ∣ g ; g′ ∣ ℓ ; ℓ′ ⊢ compile M ⊢M ⊑ compile M′ ⊢M′ ⇐ A ⊑ A′)


{- There are quite a few cases about compiling an if-conditional,
   so let's put them in a separate lemma. -}
postulate
  compile-pres-precision-if : ∀ {Γ Γ′ g g′ M M′ L L′ N₁ N₁′ N₂ N₂′ A A′} {p}
    → Γ ⊑* Γ′
    → g ⊑ₗ g′
    → ⊢ M ⊑ᴳ M′
    → (⊢M  : Γ  ; g  ⊢ᴳ M  ⦂ A )
    → (⊢M′ : Γ′ ; g′ ⊢ᴳ M′ ⦂ A′)
    → M  ≡ if L  then N₁  else N₂  at p
    → M′ ≡ if L′ then N₁′ else N₂′ at p
      --------------------------------------------------------------------------------------------
    → (∀ {ℓ ℓ′} → Γ ; Γ′ ∣ ∅ ; ∅ ∣ g ; g′ ∣ ℓ ; ℓ′ ⊢ compile M ⊢M ⊑ compile M′ ⊢M′ ⇐ A ⊑ A′)
-- compile-pres-precision-if Γ⊑Γ′ gc⊑gc′ (⊑ᴳ-if L⊑L′ M⊑M′ N⊑N′)
--     (⊢if {gc = gc}  {A = A}  {B}  {C}  {g = g}  ⊢L  ⊢M  ⊢N  A∨̃B≡C)
--     (⊢if {gc = gc′} {A = A′} {B′} {C′} {g = g′} ⊢L′ ⊢M′ ⊢N′ A′∨̃B′≡C′) eq eq′
--   with compile-pres-precision Γ⊑Γ′ gc⊑gc′ L⊑L′ ⊢L ⊢L′
-- ... | 𝒞L⊑𝒞L′
--   with cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞L⊑𝒞L′
-- ... | ⟨ _ , _ , ⊑-ty g⊑g′ ⊑-ι ⟩
--   with compile-pres-precision Γ⊑Γ′ (consis-join-⊑ₗ gc⊑gc′ g⊑g′) M⊑M′ ⊢M ⊢M′
--      | compile-pres-precision Γ⊑Γ′ (consis-join-⊑ₗ gc⊑gc′ g⊑g′) N⊑N′ ⊢N ⊢N′
-- ... | 𝒞M⊑𝒞M′ | 𝒞N⊑𝒞N′
--   with cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞M⊑𝒞M′
--      | cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞N⊑𝒞N′
-- ... | ⟨ _ , _ , A⊑A′ ⟩ | ⟨ _ , _ , B⊑B′ ⟩
--   with consis-join-≲-inv {A} {B} A∨̃B≡C | consis-join-≲-inv {A′} {B′} A′∨̃B′≡C′
-- ... | ⟨ A≲C , B≲C ⟩ | ⟨ A′≲C′ , B′≲C′ ⟩
--   with gc | g | gc′ | g′ | C | C′ | g⊑g′ | gc⊑gc′
-- ... | l _ | l ℓ | l _ | l ℓ′ | _ | _ | l⊑l | l⊑l =
--   ⊑-if (compile-pres-precision Γ⊑Γ′ l⊑l L⊑L′ ⊢L ⊢L′)
--        (⊑-cast (compile-pres-precision Γ⊑Γ′ ⊑ₗ-refl M⊑M′ ⊢M ⊢M′)
--                (coerce-prec A⊑A′ (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) A≲C A′≲C′))
--        (⊑-cast (compile-pres-precision Γ⊑Γ′ ⊑ₗ-refl N⊑N′ ⊢N ⊢N′)
--                (coerce-prec B⊑B′ (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) B≲C B′≲C′))
--        refl refl
-- ... | l _ | ⋆ | l _ | l ℓ′ | T of ⋆ | T′ of g₁ | ⋆⊑ | l⊑l =
--   let C⊑C′ : T of ⋆ ⊑ T′ of g₁
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′)
--       prec : stamp (T of ⋆) ⋆ ⊑ stamp (T′ of g₁) (l ℓ′)
--       prec = stamp-⊑ C⊑C′ ⋆⊑ in
--   case C⊑C′ of λ where
--   (⊑-ty ℓ⊑g₁ T⊑T′) →
--     ⊑-castl (⊑-if⋆l (⊑-castl (compile-pres-precision Γ⊑Γ′ l⊑l L⊑L′ ⊢L ⊢L′) (inject-prec-left (⊑-ty ⋆⊑ ⊑-ι)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′) (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′) (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′))) refl) (coerce-prec-left prec prec (≲-ty ≾-⋆l _))
-- ... | l _ | ⋆ | l _ | l ℓ′ | T of l ℓ | T′ of g₁ | ⋆⊑ | l⊑l =
--   let C⊑C′ : T of l ℓ ⊑ T′ of g₁
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′)
--       prec : stamp (T of l ℓ) ⋆ ⊑ stamp (T′ of g₁) (l ℓ′)
--       prec = stamp-⊑ C⊑C′ ⋆⊑ in
--   case C⊑C′ of λ where
--   (⊑-ty ℓ⊑g₁ T⊑T′) →
--     ⊑-castl (⊑-if⋆l (⊑-castl (compile-pres-precision Γ⊑Γ′ l⊑l L⊑L′ ⊢L ⊢L′) (inject-prec-left (⊑-ty ⋆⊑ ⊑-ι)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′) (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′) (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′))) refl) (coerce-prec-left prec prec (≲-ty ≾-⋆l _))
-- ... | ⋆ | l _ | l _ | l ℓ′ | T of ⋆ | T′ of g₁ | l⊑l | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of g₁
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′)
--       prec : stamp (T of ⋆) ⋆ ⊑ stamp (T′ of g₁) (l ℓ′)
--       prec = stamp-⊑ C⊑C′ ⋆⊑ in
--   case C⊑C′ of λ where
--   (⊑-ty ℓ⊑g₁ T⊑T′) →
--     ⊑-castl (⊑-if⋆l (⊑-castl (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec-left (⊑-ty l⊑l ⊑-ι)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′) (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′) (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′))) refl) (coerce-prec-left prec prec (≲-ty ≾-⋆l _))
-- ... | ⋆ | l _ | l _ | l ℓ′ | T of l ℓ | T′ of g₁ | l⊑l | ⋆⊑ =
--   let C⊑C′ : T of l ℓ ⊑ T′ of g₁
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′)
--       prec₁ : stamp (T of l ℓ) ⋆ ⊑ stamp (T′ of g₁) (l ℓ′)
--       prec₁ = stamp-⊑ C⊑C′ ⋆⊑
--       prec₂ : stamp (T of l ℓ) (l ℓ′) ⊑ stamp (T′ of g₁) (l ℓ′)
--       prec₂ = stamp-⊑ C⊑C′ l⊑l in
--   case C⊑C′ of λ where
--   (⊑-ty ℓ⊑g₁ T⊑T′) →
--     ⊑-castl (⊑-if⋆l (⊑-castl (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec-left (⊑-ty l⊑l ⊑-ι)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′) (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′) (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′))) refl) (coerce-prec-left prec₁ prec₂ (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | l _ | l ℓ′ | T of ⋆ | T′ of g₁ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of g₁
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′)
--       prec : stamp (T of ⋆) ⋆ ⊑ stamp (T′ of g₁) (l ℓ′)
--       prec = stamp-⊑ C⊑C′ ⋆⊑ in
--   case C⊑C′ of λ where
--   (⊑-ty ℓ⊑g₁ T⊑T′) →
--     ⊑-castl (⊑-if⋆l (⊑-castl (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec-left (⊑-ty ⋆⊑ ⊑-ι)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′) (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′) (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′))) refl) (coerce-prec-left prec prec (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | l _ | l ℓ′ | T of l ℓ | T′ of g₁ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of l ℓ ⊑ T′ of g₁
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′)
--       prec : stamp (T of l ℓ) ⋆ ⊑ stamp (T′ of g₁) (l ℓ′)
--       prec = stamp-⊑ C⊑C′ ⋆⊑ in
--   case C⊑C′ of λ where
--   (⊑-ty ℓ⊑g₁ T⊑T′) →
--     ⊑-castl (⊑-if⋆l (⊑-castl (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec-left (⊑-ty ⋆⊑ ⊑-ι)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′) (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′)))
--                     (⊑-castl (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′) (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                              (inject-prec-left (⊑-ty ℓ⊑g₁ T⊑T′))) refl) (coerce-prec-left prec prec (≲-ty ≾-⋆l _))
-- ... | l _ | ⋆ | l _ | ⋆ | T of ⋆ | T′ of ⋆ | ⋆⊑ | l⊑l =
--   let C⊑C′ : T of ⋆ ⊑ T′ of ⋆
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ l⊑l L⊑L′ ⊢L ⊢L′) (inject-prec ⊑-refl))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec C⊑C′ C⊑C′ (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | l _ | ⋆ | l _ | ⋆ | T of ⋆ | T′ of l ℓ | ⋆⊑ | l⊑l =
--   let C⊑C′ : T of ⋆ ⊑ T′ of l ℓ
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let prec : T of ⋆ ⊑ T′ of ⋆
--       prec = case C⊑C′ of λ where
--                (⊑-ty _ T⊑T′) → ⊑-ty ⋆⊑ T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ l⊑l L⊑L′ ⊢L ⊢L′) (inject-prec ⊑-refl))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec prec prec (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | l _ | ⋆ | l _ | ⋆ | T of l ℓ | T′ of ⋆ | ⋆⊑ | l⊑l =
--   let C⊑C′ : T of l ℓ ⊑ T′ of ⋆  -- however, C ⊑ C′ is impossible
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   case C⊑C′ of λ where (⊑-ty () _)
-- ... | l _ | ⋆ | l _ | ⋆ | T of l ℓ₁ | T′ of l ℓ₂ | ⋆⊑ | l⊑l =
--   let C⊑C′ : T of l ℓ₁ ⊑ T′ of l ℓ₂
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let prec : T of ⋆ ⊑ T′ of ⋆
--       prec = case C⊑C′ of λ where
--                (⊑-ty _ T⊑T′) → ⊑-ty ⋆⊑ T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ l⊑l L⊑L′ ⊢L ⊢L′) (inject-prec ⊑-refl))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec prec prec (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))

-- ... | ⋆ | l _ | ⋆ | l _ | T of ⋆ | T′ of ⋆ | l⊑l | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of ⋆
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec ⊑-refl))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec C⊑C′ C⊑C′ (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | l _ | ⋆ | l _ | T of ⋆ | T′ of l ℓ | l⊑l | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of l ℓ
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec ⊑-refl))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) (⊑-ty ⋆⊑ T⊑T′) (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | l _ | ⋆ | l _ | T of l ℓ | T′ of ⋆ | l⊑l | ⋆⊑ =
--   let C⊑C′ : T of l ℓ ⊑ T′ of ⋆  -- however, C ⊑ C′ is impossible
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   case C⊑C′ of λ where (⊑-ty () _)
-- ... | ⋆ | l ℓ | ⋆ | l ℓ | T of l ℓ₁ | T′ of l ℓ₂ | l⊑l | ⋆⊑ =
--   let C⊑C′ : T of l ℓ₁ ⊑ T′ of l ℓ₂
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   let prec : T of l (ℓ₁ ⋎ ℓ) ⊑ T′ of l (ℓ₂ ⋎ ℓ)
--       prec = stamp-⊑ C⊑C′ l⊑l in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec ⊑-refl))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) prec (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))

-- ... | ⋆ | ⋆ | ⋆ | l _ | T of ⋆ | T′ of ⋆ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of ⋆
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec C⊑C′ C⊑C′ (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | ⋆ | l _ | T of ⋆ | T′ of l ℓ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of l ℓ
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) (⊑-ty ⋆⊑ T⊑T′) (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | ⋆ | l _ | T of l ℓ | T′ of ⋆ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of l ℓ ⊑ T′ of ⋆  -- however, C ⊑ C′ is impossible
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   case C⊑C′ of λ where (⊑-ty () _)
-- ... | ⋆ | ⋆ | ⋆ | l _ | T of l ℓ₁ | T′ of l ℓ₂ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of l ℓ₁ ⊑ T′ of l ℓ₂
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) (⊑-ty ⋆⊑ T⊑T′) (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))

-- ... | ⋆ | ⋆ | l _ | ⋆ | T of ⋆ | T′ of ⋆ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of ⋆
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec C⊑C′ C⊑C′ (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | l _ | ⋆ | T of ⋆ | T′ of l ℓ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of l ℓ
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) (⊑-ty ⋆⊑ T⊑T′) (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | l _ | ⋆ | T of l ℓ | T′ of ⋆ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of l ℓ ⊑ T′ of ⋆  -- however, C ⊑ C′ is impossible
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   case C⊑C′ of λ where (⊑-ty () _)
-- ... | ⋆ | ⋆ | l _ | ⋆ | T of l ℓ₁ | T′ of l ℓ₂ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of l ℓ₁ ⊑ T′ of l ℓ₂
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) (⊑-ty ⋆⊑ T⊑T′) (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))

-- ... | ⋆ | ⋆ | ⋆ | ⋆ | T of ⋆ | T′ of ⋆ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of ⋆
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec C⊑C′ C⊑C′ (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | ⋆ | ⋆ | T of ⋆ | T′ of l ℓ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of ⋆ ⊑ T′ of l ℓ
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) (⊑-ty ⋆⊑ T⊑T′) (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))
-- ... | ⋆ | ⋆ | ⋆ | ⋆ | T of l ℓ | T′ of ⋆ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of l ℓ ⊑ T′ of ⋆  -- however, C ⊑ C′ is impossible
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   case C⊑C′ of λ where (⊑-ty () _)
-- ... | ⋆ | ⋆ | ⋆ | ⋆ | T of l ℓ₁ | T′ of l ℓ₂ | ⋆⊑ | ⋆⊑ =
--   let C⊑C′ : T of l ℓ₁ ⊑ T′ of l ℓ₂
--       C⊑C′ = (consis-join-⊑ A⊑A′ B⊑B′ A∨̃B≡C A′∨̃B′≡C′) in
--   let T⊑T′ : T ⊑ᵣ T′
--       T⊑T′ = case C⊑C′ of λ where (⊑-ty _ T⊑T′) → T⊑T′ in
--   ⊑-cast (⊑-if⋆ (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ L⊑L′ ⊢L ⊢L′) (inject-prec (⊑-ty ⋆⊑ ⊑-ι)))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ M⊑M′ ⊢M ⊢M′)
--                                 (coerce-prec A⊑A′ C⊑C′ A≲C A′≲C′))
--                         (inject-prec C⊑C′))
--                 (⊑-cast (⊑-cast (compile-pres-precision Γ⊑Γ′ ⋆⊑ N⊑N′ ⊢N ⊢N′)
--                                 (coerce-prec B⊑B′ C⊑C′ B≲C B′≲C′))
--                         (inject-prec C⊑C′)))
--          (coerce-prec (⊑-ty ⋆⊑ T⊑T′) (⊑-ty ⋆⊑ T⊑T′) (≲-ty ≾-⋆l _) (≲-ty ≾-⋆l _))


compile-pres-precision-assign : ∀ {Γ Γ′ g g′ M M′ L L′ N N′ A A′} {p}
  → Γ ⊑* Γ′
  → g ⊑ₗ g′
  → ⊢ M ⊑ᴳ M′
  → (⊢M  : Γ  ; g  ⊢ᴳ M  ⦂ A )
  → (⊢M′ : Γ′ ; g′ ⊢ᴳ M′ ⦂ A′)
  → M  ≡ L  := N  at p
  → M′ ≡ L′ := N′ at p
    --------------------------------------------------------------------------------------------
  → (∀ {ℓ ℓ′} → Γ ; Γ′ ∣ ∅ ; ∅ ∣ g ; g′ ∣ ℓ ; ℓ′ ⊢ compile M ⊢M ⊑ compile M′ ⊢M′ ⇐ A ⊑ A′)
compile-pres-precision-assign Γ⊑Γ′ gc⊑gc′ (⊑ᴳ-assign L⊑L′ M⊑M′)
    (⊢assign {gc = gc } {g = g } {ĝ } ⊢L  ⊢M  A≲Tĝ   g≾ĝ   gc≾ĝ  )
    (⊢assign {gc = gc′} {g = g′} {ĝ′} ⊢L′ ⊢M′ A′≲Tĝ′ g′≾ĝ′ gc′≾ĝ′) _ _
  with all-specific-dec [ gc , g , ĝ ] | all-specific-dec [ gc′ , g′ , ĝ′ ]
... | no _ | yes (as-cons (specific ℓ₁)  (as-cons (specific ℓ₂)  (as-cons (specific ℓ₃) as-nil))) =
  let 𝒞L⊑𝒞L′ = compile-pres-precision Γ⊑Γ′ gc⊑gc′ L⊑L′ ⊢L ⊢L′ in
  let 𝒞M⊑𝒞M′ = compile-pres-precision Γ⊑Γ′ gc⊑gc′ M⊑M′ ⊢M ⊢M′ in
  case ⟨ g′≾ĝ′ , gc′≾ĝ′ ⟩ of λ where
  ⟨ ≾-l g′≼ĝ′ , ≾-l gc′≼ĝ′ ⟩ →
    case   cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞L⊑𝒞L′ of λ where
    ⟨ _ , _ , ⊑-ty g⊑g′ (⊑-ref B⊑B′) ⟩ →
      case cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞M⊑𝒞M′ of λ where
      ⟨ _ , _ , A⊑A′ ⟩ →
        ⊑-assign?l (⊑-castl 𝒞L⊑𝒞L′ (inject-prec-left (⊑-ty g⊑g′ (⊑-ref B⊑B′))))
                   (⊑-cast  𝒞M⊑𝒞M′ (coerce-prec A⊑A′ B⊑B′ A≲Tĝ A′≲Tĝ′))
                   gc′≼ĝ′ g′≼ĝ′
... | yes (as-cons (specific ℓ₁)  (as-cons (specific ℓ₂)  (as-cons (specific ℓ₃) as-nil))) | no ¬as =
  let 𝒞L⊑𝒞L′ = compile-pres-precision Γ⊑Γ′ gc⊑gc′ L⊑L′ ⊢L ⊢L′ in
  case ⟨ gc⊑gc′ , cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞L⊑𝒞L′ ⟩ of λ where
  ⟨ l⊑l {.ℓ₁} , _ , _ , ⊑-ty (l⊑l {.ℓ₂}) (⊑-ref (⊑-ty (l⊑l {.ℓ₃}) T⊑T′)) ⟩ →
    let as = as-cons (specific ℓ₁) (as-cons (specific ℓ₂) (as-cons (specific ℓ₃) as-nil)) in
    contradiction as ¬as
... | no _ | no _ =
  let 𝒞L⊑𝒞L′ = compile-pres-precision Γ⊑Γ′ gc⊑gc′ L⊑L′ ⊢L ⊢L′ in
  let 𝒞M⊑𝒞M′ = compile-pres-precision Γ⊑Γ′ gc⊑gc′ M⊑M′ ⊢M ⊢M′ in
    case   cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞L⊑𝒞L′ of λ where
    ⟨ _ , _ , ⊑-ty g⊑g′ (⊑-ref B⊑B′) ⟩ →
      case cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞M⊑𝒞M′ of λ where
      ⟨ _ , _ , A⊑A′ ⟩ →
        ⊑-assign? (⊑-cast 𝒞L⊑𝒞L′ (inject-prec (⊑-ty g⊑g′ (⊑-ref B⊑B′))))
                  (⊑-cast 𝒞M⊑𝒞M′ (coerce-prec A⊑A′ B⊑B′ A≲Tĝ A′≲Tĝ′))
... | yes (as-cons (specific ℓ₁ )  (as-cons (specific ℓ₂ )  (as-cons (specific ℓ₃ ) as-nil)))
    | yes (as-cons (specific ℓ₁′)  (as-cons (specific ℓ₂′)  (as-cons (specific ℓ₃′) as-nil)))
  with gc⊑gc′ | g≾ĝ     | gc≾ĝ
...  | l⊑l    | ≾-l g≼ĝ | ≾-l gc≼ĝ =
  let 𝒞L⊑𝒞L′ = compile-pres-precision Γ⊑Γ′ gc⊑gc′ L⊑L′ ⊢L ⊢L′ in
  let 𝒞M⊑𝒞M′ = compile-pres-precision Γ⊑Γ′ gc⊑gc′ M⊑M′ ⊢M ⊢M′ in
  case   cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞L⊑𝒞L′ of λ where
  ⟨ _ , _ , ⊑-ty l⊑l (⊑-ref (⊑-ty l⊑l T⊑T′)) ⟩ →
    case cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞M⊑𝒞M′ of λ where
    ⟨ _ , _ , A⊑A′ ⟩ →
      ⊑-assign 𝒞L⊑𝒞L′ (⊑-cast 𝒞M⊑𝒞M′
                               (coerce-prec A⊑A′ (⊑-ty l⊑l T⊑T′) A≲Tĝ A′≲Tĝ′))
               gc≼ĝ g≼ĝ



{- Compiling values -}
compile-pres-precision Γ⊑Γ′ g⊑g′ ⊑ᴳ-const ⊢const ⊢const = ⊑-const
compile-pres-precision Γ⊑Γ′ g⊑g′ ⊑ᴳ-var (⊢var Γ∋x⦂A) (⊢var Γ′∋x⦂A′) = ⊑-var Γ∋x⦂A Γ′∋x⦂A′
compile-pres-precision Γ⊑Γ′ g⊑g′ (⊑ᴳ-lam g₁⊑g₂ A⊑A′ M⊑M′) (⊢lam ⊢M) (⊢lam ⊢M′) =
  ⊑-lam g₁⊑g₂ A⊑A′ (compile-pres-precision (⊑*-∷ A⊑A′ Γ⊑Γ′) g₁⊑g₂ M⊑M′ ⊢M ⊢M′)
{- Compiling function application -}
compile-pres-precision Γ⊑Γ′ g⊑g′ (⊑ᴳ-app M⊑M′ M⊑M′₁) ⊢M ⊢M′ = {!!}
{- Compiling if-conditional -}
compile-pres-precision Γ⊑Γ′ gc⊑gc′ (⊑ᴳ-if L⊑L′ N₁⊑N₁′ N₂⊑N₂′) ⊢M ⊢M′ =
  compile-pres-precision-if Γ⊑Γ′ gc⊑gc′ (⊑ᴳ-if L⊑L′ N₁⊑N₁′ N₂⊑N₂′) ⊢M ⊢M′ refl refl
{- Compiling type annotation -}
compile-pres-precision Γ⊑Γ′ g⊑g′ (⊑ᴳ-ann M⊑M′ A⊑A′) (⊢ann ⊢M B≲A) (⊢ann ⊢M′ B′≲A′) =
  let 𝒞M⊑𝒞M′ = compile-pres-precision Γ⊑Γ′ g⊑g′ M⊑M′ ⊢M ⊢M′ in
  let ⟨ _ , _ , B⊑B′ ⟩ = cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞M⊑𝒞M′ in
  ⊑-cast 𝒞M⊑𝒞M′ (coerce-prec B⊑B′ A⊑A′ B≲A B′≲A′)
{- Compiling let-expression -}
compile-pres-precision Γ⊑Γ′ g⊑g′ (⊑ᴳ-let M⊑M′ N⊑N′) (⊢let ⊢M ⊢N) (⊢let ⊢M′ ⊢N′) =
  let 𝒞M⊑𝒞M′ = compile-pres-precision Γ⊑Γ′ g⊑g′ M⊑M′ ⊢M ⊢M′ in
  let ⟨ _ , _ , A⊑A′ ⟩ = cc-prec-inv {ℓv = low} {low} Γ⊑Γ′ ⟨ ⊑-∅ , ⊑-∅ ⟩ 𝒞M⊑𝒞M′ in
  ⊑-let 𝒞M⊑𝒞M′ (compile-pres-precision (⊑*-∷ A⊑A′ Γ⊑Γ′) g⊑g′ N⊑N′ ⊢N ⊢N′)
compile-pres-precision Γ⊑Γ′ g⊑g′ (⊑ᴳ-ref M⊑M′) ⊢M ⊢M′ = {!!}
compile-pres-precision Γ⊑Γ′ g⊑g′ (⊑ᴳ-deref M⊑M′) ⊢M ⊢M′ = {!!}
compile-pres-precision Γ⊑Γ′ g⊑g′ (⊑ᴳ-assign L⊑L′ M⊑M′)
                       (⊢assign {gc = gc } {g = g } {ĝ } ⊢L ⊢M A≲Tĝ g≾ĝ gc≾ĝ)
                       (⊢assign {gc = gc′} {g = g′} {ĝ′} ⊢L′ ⊢M′ A′≲Tĝ′ g′≾ĝ′ gc′≾ĝ′) = {!!}
