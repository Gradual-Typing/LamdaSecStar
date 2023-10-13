module Simulation.Cast where

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
open import CoercionExpr.Precision using (coerce⇒⋆-prec; ⊑-right-contract)
open import CoercionExpr.SyntacComp
open import CoercionExpr.GG using (sim-mult)
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
open import CC2.SubstPrecision using (substitution-pres-⊑)
open import Memory.Heap Term Value hiding (Addr; a⟦_⟧_)

open import Simulation.SimCast



sim-cast-step : ∀ {Σ Σ′ gc gc′} {M N′ V′ μ μ′ PC PC′} {A A′ B′ C′} {c′ : Cast B′ ⇒ C′}
    → (vc  : LVal PC)
    → (vc′ : LVal PC′)
    → let ℓv  = ∥ PC  ∥ vc  in
      let ℓv′ = ∥ PC′ ∥ vc′ in
      [] ; [] ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ M ⊑ V′ ⟨ c′ ⟩ ⇐ A ⊑ A′
    → Σ ⊑ₘ Σ′
    → Σ ; Σ′ ⊢ μ ⊑ μ′
    → PC ⊑ PC′ ⇐ gc ⊑ gc′
    → SizeEq μ μ′
    → Value V′
    → V′ ⟨ c′ ⟩ —→ N′
      --------------------------------------------------------------------------
    → ∃[ N ] (M ∣ μ ∣ PC —↠ N ∣ μ) ×
            ([] ; [] ∣ Σ ; Σ′ ∣ gc ; gc′ ∣ ℓv ; ℓv′ ⊢ N ⊑ N′ ⇐ A ⊑ A′)
sim-cast-step {μ = μ} {PC = PC} vc vc′ (⊑-cast M⊑V′ c⊑c′) Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq (V-raw _) (cast v′ c̅′→⁺c̅ₙ 𝓋′) =
  case catchup {μ = μ} {PC = PC} (V-raw v′) M⊑V′ of λ where
  ⟨ _ , V-raw v , M↠V , V⊑V′ ⟩ → {!!}
  ⟨ _ , V-cast v i , M↠V , ⊑-castl V⊑V′ c₁⊑A′ ⟩ →
    case ⟨ c₁⊑A′ ,  c⊑c′ , V⊑V′ ⟩ of λ where
    ⟨ ⊑-base c̅₁⊑g′ , ⊑-base c̅⊑c̅′ , ⊑-const ⟩ →
      case sim-mult (comp-pres-⊑-lb c̅₁⊑g′ c̅⊑c̅′) 𝓋′ (→⁺-impl-↠ c̅′→⁺c̅ₙ) of λ where
      ⟨ c̅ₙ , id , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult (plug-cong □⟨ _ ⟩ M↠V)
                     (_ ∣ _ ∣ _ —→⟨ cast (V-cast V-const i) (cast-comp V-const i) ⟩
                      _ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) (cast V-const (comp-→⁺ ↠c̅ₙ CVal.id) CVal.id) ⟩
                      _ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) cast-id ⟩
                      _ ∣ _ ∣ _ ∎) ,
          ⊑-castr ⊑-const (⊑-base (⊑-right-contract c̅ₙ⊑c̅ₙ′)) ⟩
      ⟨ c̅ₙ , up id , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult (plug-cong □⟨ _ ⟩ M↠V)
                     (_ ∣ _ ∣ _ —→⟨ cast (V-cast V-const i) (cast-comp V-const i) ⟩
                      _ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) (cast V-const (comp-→⁺ ↠c̅ₙ (up CVal.id)) (up CVal.id)) ⟩
                      _ ∣ _ ∣ _ ∎) ,
          ⊑-cast ⊑-const (⊑-base c̅ₙ⊑c̅ₙ′) ⟩
      ⟨ c̅ₙ , inj 𝓋 , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult (plug-cong □⟨ _ ⟩ M↠V)
                     (_ ∣ _ ∣ _ —→⟨ cast (V-cast V-const i) (cast-comp V-const i) ⟩
                      _ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) (cast V-const (comp-→⁺ ↠c̅ₙ (inj 𝓋)) (inj 𝓋)) ⟩
                      _ ∣ _ ∣ _ ∎) ,
          ⊑-cast ⊑-const (⊑-base c̅ₙ⊑c̅ₙ′) ⟩
    ⟨ ⊑-ref c₁⊑A′ d₁⊑A′ c̅₁⊑g′ , ⊑-ref c⊑c′ d⊑d′ c̅⊑c̅′ , ⊑-addr a b ⟩ →
      case sim-mult (comp-pres-⊑-lb c̅₁⊑g′ c̅⊑c̅′) 𝓋′ (→⁺-impl-↠ c̅′→⁺c̅ₙ) of λ where
      ⟨ c̅ₙ , 𝓋 , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult (plug-cong □⟨ _ ⟩ M↠V)
                     (_ ∣ _ ∣ _ —→⟨ cast (V-cast V-addr i) (cast-comp V-addr i) ⟩
                      _ ∣ _ ∣ _ —→⟨ cast (V-raw V-addr) (cast V-addr (comp-→⁺ ↠c̅ₙ 𝓋) 𝓋) ⟩
                      _ ∣ _ ∣ _ ∎) ,
          ⊑-cast (⊑-addr a b) (⊑-ref (comp-pres-prec-bl c⊑c′ c₁⊑A′) (comp-pres-prec-lb d₁⊑A′ d⊑d′) c̅ₙ⊑c̅ₙ′) ⟩
    ⟨ ⊑-fun d̅₁⊑gc′ c₁⊑A′ d₁⊑B′ c̅₁⊑g′ , ⊑-fun d̅⊑d̅′ c⊑c′ d⊑d′ c̅⊑c̅′ , ⊑-lam gc⊑gc′ A⊑A′ N⊑N′ ⟩ →
      case sim-mult (comp-pres-⊑-lb c̅₁⊑g′ c̅⊑c̅′) 𝓋′ (→⁺-impl-↠ c̅′→⁺c̅ₙ) of λ where
      ⟨ c̅ₙ , 𝓋 , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult (plug-cong □⟨ _ ⟩ M↠V)
                     (_ ∣ _ ∣ _ —→⟨ cast (V-cast V-ƛ i) (cast-comp V-ƛ i) ⟩
                      _ ∣ _ ∣ _ —→⟨ cast (V-raw V-ƛ) (cast V-ƛ (comp-→⁺ ↠c̅ₙ 𝓋) 𝓋) ⟩
                      _ ∣ _ ∣ _ ∎) ,
          ⊑-cast (⊑-lam gc⊑gc′ A⊑A′ N⊑N′)
                 (⊑-fun (comp-pres-⊑-bl d̅⊑d̅′ d̅₁⊑gc′)
                        (comp-pres-prec-bl c⊑c′ c₁⊑A′)
                        (comp-pres-prec-lb d₁⊑B′ d⊑d′) c̅ₙ⊑c̅ₙ′) ⟩
  ⟨ _ , V-● , M↠● , ●⊑V′ ⟩ → contradiction ●⊑V′ (●⋤ _)
sim-cast-step {μ = μ} {PC = PC} vc vc′ (⊑-castr M⊑V′ A⊑c′) Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ (cast vᵣ′ c̅′→⁺c̅ₙ′ 𝓋′) =
  case catchup {μ = μ} {PC = PC} v′ M⊑V′ of λ where
  ⟨ _ , V-raw v , M↠V , V⊑V′ ⟩ → {!!}
  ⟨ _ , V-cast v i , M↠V , ⊑-castl V⊑V′ c₁⊑A′ ⟩ →
    case ⟨ comp-pres-prec-lr c₁⊑A′ A⊑c′ , V⊑V′ ⟩ of λ where
    ⟨ ⊑-base c̅⊑c̅′ , ⊑-const ⟩ →
      case sim-mult c̅⊑c̅′ 𝓋′ (→⁺-impl-↠ c̅′→⁺c̅ₙ′) of λ where
      ⟨ c̅ₙ , id , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult M↠V
                     (case ↠c̅ₙ of λ where
                      (_ ∎ₗ) →
                        _ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) cast-id ⟩
                         _ ∣ _ ∣ _ ∎
                      (_ —→ₗ⟨ r ⟩ r*) →
                        _ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) (cast V-const (_ —→ₗ⟨ r ⟩ r*) CVal.id) ⟩
                        _ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) cast-id ⟩
                        _ ∣ _ ∣ _ ∎) ,
          ⊑-castr ⊑-const (⊑-base (⊑-right-contract c̅ₙ⊑c̅ₙ′)) ⟩
      ⟨ c̅ₙ , up id , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult M↠V
                     (_ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) (cast V-const {!!} (up CVal.id)) ⟩
                      _ ∣ _ ∣ _ ∎) ,
          ⊑-cast ⊑-const (⊑-base c̅ₙ⊑c̅ₙ′) ⟩
      ⟨ c̅ₙ , inj 𝓋 , ↠c̅ₙ , c̅ₙ⊑c̅ₙ′ ⟩ →
        ⟨ _ ,
          trans-mult M↠V
                     (_ ∣ _ ∣ _ —→⟨ cast (V-raw V-const) (cast V-const {!!} (inj 𝓋)) ⟩
                      _ ∣ _ ∣ _ ∎) ,
          ⊑-cast ⊑-const (⊑-base c̅ₙ⊑c̅ₙ′) ⟩
    ⟨ ⊑-ref c⊑c′ d⊑d′ c̅⊑c̅′ , ⊑-addr a b ⟩ →
      {!!}
    ⟨ ⊑-fun d̅⊑d̅′ c⊑c′ d⊑d′ c̅⊑c̅′ , ⊑-lam gc⊑gc′ A⊑A′ N⊑N′ ⟩ →
      {!!}
  ⟨ _ , V-● , M↠● , ●⊑V′ ⟩ → contradiction ●⊑V′ (●⋤ _)
sim-cast-step vc vc′ prec Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ (cast-blame x x₁) = {!!}
sim-cast-step vc vc′ prec Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ cast-id = {!!}
sim-cast-step vc vc′ (⊑-cast prec x₂) Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ (cast-comp x x₁) = {!!}
sim-cast-step vc vc′ (⊑-castr prec x₂) Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ (cast-comp x x₁) = {!!}
sim-cast-step vc vc′ (⊑-castl {c = c} M⊑M′ c⊑A′) Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ r =
  case sim-cast-step vc vc′ M⊑M′ Σ⊑Σ′ μ⊑μ′ PC⊑PC′ size-eq v′ r of λ where
  ⟨ N , M↠N , N⊑N′ ⟩ →
    ⟨ N ⟨ c ⟩ , plug-cong □⟨ c ⟩ M↠N , ⊑-castl N⊑N′ c⊑A′ ⟩
