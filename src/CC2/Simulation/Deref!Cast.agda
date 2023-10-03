module CC2.Simulation.Deref!Cast where

open import Data.Nat
open import Data.Unit using (⊤; tt)
open import Data.Bool using (true; false) renaming (Bool to 𝔹)
open import Data.List hiding ([_])
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
open import CoercionExpr.Precision using (coerce⇒⋆-prec)
open import CoercionExpr.SyntacComp
open import LabelExpr.CatchUp renaming (catchup to catchupₑ)
open import LabelExpr.Security
open import LabelExpr.Stamping
open import LabelExpr.NSU
open import CC2.Statics
open import CC2.Reduction
open import CC2.MultiStep
open import CC2.Precision
open import CC2.HeapPrecision
open import CC2.CatchUp
open import CC2.SimCast
open import CC2.SubstPrecision using (substitution-pres-⊑)
open import Memory.Heap Term Value hiding (Addr; a⟦_⟧_)


sim-deref!-cast : ∀ {Σ Σ′ gc gc′} {M V′ μ μ′ PC PC′} {A A′ B′ T n ℓ ℓ̂}
                    {c : Cast B′ ⇒ T of l ℓ̂} {d : Cast T of l ℓ̂ ⇒ B′} {c̅ₙ : CExpr l ℓ ⇒ ⋆}
  → (vc  : LVal PC)
  → (vc′ : LVal PC′)
  → let ℓv  = ∥ PC  ∥ vc  in
     let ℓv′ = ∥ PC′ ∥ vc′ in
     [] ; [] ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ M ⊑ !! (addr n ⟨ cast (ref c d) c̅ₙ ⟩) B′ ⇐ A ⊑ A′
  → Σ ⊑ₘ Σ′
  → Σ ; Σ′ ⊢ μ ⊑ μ′
  → PC ⊑ PC′ ⇐ gc ⊑ gc′
  → SizeEq μ μ′
  → (v′ : Value V′)
  → (𝓋′ : CVal c̅ₙ)
  → lookup-μ μ′ (a⟦ ℓ̂ ⟧ n) ≡ just (V′ & v′)
    -------------------
  → let ℓ′ = ∥ c̅ₙ ∥ₗ 𝓋′ in
        ∃[ N ] (M ∣ μ ∣ PC —↠ N ∣ μ) ×
             ([] ; [] ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ N ⊑ prot! (l high) v-l ℓ′ (V′ ⟨ d ⟩) B′ ⇐ A ⊑ A′)
sim-deref!-cast {Σ} {Σ′} {gc} {gc′} {μ = μ} {PC = PC} {PC′} vc vc′
      (⊑-deref! M⊑M′ eq eq′) Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ 𝓋′ μ′a≡V′
  with catchup {μ = μ} {PC} (V-cast V-addr (ir-ref 𝓋′)) M⊑M′
... | ⟨ addr _ , V-raw V-addr , L↠V , ⊑-castr () _ ⟩
... | ⟨ _ , V-cast V-addr (ir-ref 𝓋) , L↠V , ⊑-cast (⊑-addr {n = n} {ℓ̂ = ℓ̂} a b) c⊑c′ ⟩ =
  let ⟨ _ , _ , V , v , V′ , v′ , μa≡V , μ′a≡V†′ , V⊑V′ ⟩ = μ⊑μ′ n ℓ̂ a b in
  let ♣ = trans-mult (plug-cong (!!□ _) L↠V)
                     (_ ∣ _ ∣ _ —→⟨ deref!-cast {v = v} 𝓋 μa≡V ⟩ _ ∣ _ ∣ _ ∎) in
  case c⊑c′ of λ where
  (⊑-ref c⊑c′ d⊑d′ c̅⊑c̅′) →
    case trans (sym μ′a≡V′) μ′a≡V†′ of λ where
    refl →
      let ∣c̅∣≼∣c̅′∣ = security-prec _ _ 𝓋 𝓋′ c̅⊑c̅′ in
      ⟨ _ , ♣ , ⊑-prot! (⊑-cast (value-⊑-pc V⊑V′ v v′) d⊑d′) ⊑-l (_ ≼high) (_ ≼high) eq eq′ ∣c̅∣≼∣c̅′∣ ⟩
... | ⟨ _ , V-cast V-addr (ir-ref 𝓋) , L↠V , ⊑-castl (⊑-castr (⊑-addr {n = n} {ℓ̂ = ℓ̂} a b) A⊑c′) c⊑A′ ⟩ =
  let ⟨ _ , _ , V , v , V′ , v′ , μa≡V , μ′a≡V†′ , V⊑V′ ⟩ = μ⊑μ′ n ℓ̂ a b in
  let ♣ = trans-mult (plug-cong (!!□ _) L↠V)
                     (_ ∣ _ ∣ _ —→⟨ deref!-cast {v = v} 𝓋 μa≡V ⟩ _ ∣ _ ∣ _ ∎) in
  case (comp-pres-prec-rl A⊑c′ c⊑A′) of λ where
  (⊑-ref c⊑c′ d⊑d′ c̅⊑c̅′) →
    case trans (sym μ′a≡V′) μ′a≡V†′ of λ where
    refl →
      let ∣c̅∣≼∣c̅′∣ = security-prec _ _ 𝓋 𝓋′ c̅⊑c̅′ in
      ⟨ _ , ♣ , ⊑-prot! (⊑-cast (value-⊑-pc V⊑V′ v v′) d⊑d′) ⊑-l (_ ≼high) (_ ≼high) eq eq′ ∣c̅∣≼∣c̅′∣ ⟩
... | ⟨ _ , V-cast V-const _ , L↠V , ⊑-castl (⊑-castr () _) c⊑A′ ⟩
... | ⟨ _ , V-cast V-ƛ _ , L↠V , ⊑-castl (⊑-castr () _) c⊑A′ ⟩
... | ⟨ _ , V-cast V-addr (ir-ref 𝓋) , L↠V , ⊑-castr (⊑-castl (⊑-addr {n = n} {ℓ̂ = ℓ̂} a b) c⊑A′) A⊑c′ ⟩ =
  let ⟨ _ , _ , V , v , V′ , v′ , μa≡V , μ′a≡V†′ , V⊑V′ ⟩ = μ⊑μ′ n ℓ̂ a b in
  let ♣ = trans-mult (plug-cong (!!□ _) L↠V)
                     (_ ∣ _ ∣ _ —→⟨ deref!-cast {v = v} 𝓋 μa≡V ⟩ _ ∣ _ ∣ _ ∎) in
  case (comp-pres-prec-lr c⊑A′ A⊑c′) of λ where
  (⊑-ref c⊑c′ d⊑d′ c̅⊑c̅′) →
    case trans (sym μ′a≡V′) μ′a≡V†′ of λ where
    refl →
      let ∣c̅∣≼∣c̅′∣ = security-prec _ _ 𝓋 𝓋′ c̅⊑c̅′ in
      ⟨ _ , ♣ , ⊑-prot! (⊑-cast (value-⊑-pc V⊑V′ v v′) d⊑d′) ⊑-l (_ ≼high) (_ ≼high) eq eq′ ∣c̅∣≼∣c̅′∣ ⟩
sim-deref!-cast vc vc′ (⊑-castl {c = c} M⊑M′ c⊑A′) Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ 𝓋 μ′a≡V′
  with sim-deref!-cast vc vc′ M⊑M′ Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ 𝓋 μ′a≡V′
... | ⟨ N , M↠N , N⊑N′ ⟩ =
  ⟨ N ⟨ c ⟩ , plug-cong □⟨ c ⟩ M↠N , ⊑-castl N⊑N′ c⊑A′ ⟩
