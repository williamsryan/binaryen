#include <memory>

#include "cfg/Relooper.h"
#include "ir/flat.h"
#include "ir/utils.h"
#include "pass.h"
#include "wasm-builder.h"
#include "wasm-traversal.h"
#include "wasm.h"

namespace wasm {

// Define the PrivacyPass class that inherits from the Pass class
struct PrivacyPass : public Pass {
  void run(Module* module) override {
    // Iterate over all functions in the module
    for (auto& func : module->functions) {
      if (func->body) {
        // Apply the transformation to the function body
        transform(func->body, *module);
      }
    }
  }

  // Transformation function that introduces a NOP after load/store operations
  void transform(Expression*& expr, Module& module) {
    if (expr->is<Load>()) {
      // Add a NOP after a load operation
      Builder builder(module);
      expr = builder.makeSequence(expr, builder.makeNop());
    } else if (expr->is<Store>()) {
      // Add a NOP after a store operation
      Builder builder(module);
      expr = builder.makeSequence(expr, builder.makeNop());
    } else if (auto* block = expr->dynCast<Block>()) {
      // Recursively transform expressions in a block
      for (auto& exprInBlock : block->list) {
        transform(exprInBlock, module);
      }
    } else if (auto* loop = expr->dynCast<Loop>()) {
      // Recursively transform expressions in a loop
      transform(loop->body, module);
    } else if (auto* if_ = expr->dynCast<If>()) {
      // Recursively transform expressions in an if statement
      transform(if_->ifTrue, module);
      if (if_->ifFalse) {
        transform(if_->ifFalse, module);
      }
    }
  }
};

// Register the pass with the pass registry
Pass* createPrivacyPass() { return new PrivacyPass(); }

// static RegisterPass<PrivacyPass>
//   registerPass("privacy-pass", "Add NOPs after loads and stores for
//   privacy");

} // namespace wasm