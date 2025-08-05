import Foundation
import StoreKit

@MainActor
class AdManager: ObservableObject {
    static let shared = AdManager()
    
    @Published var isPremium = false
    @Published var isAdRemovalPurchased = false
    @Published var products: [Product] = []
    
    private let adRemovalProductID = "com.sixteenhourdiet.adremoval"
    private var lastInterstitialAdTime: Date?
    private let interstitialAdInterval: TimeInterval = 60 // 60秒間隔
    
    private init() {
        loadPremiumStatus()
        Task {
            await loadProducts()
        }
    }
    
    // MARK: - Premium Status Management
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        isAdRemovalPurchased = UserDefaults.standard.bool(forKey: "isAdRemovalPurchased")
    }
    
    func savePremiumStatus() {
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
        UserDefaults.standard.set(isAdRemovalPurchased, forKey: "isAdRemovalPurchased")
    }
    
    // MARK: - Ad Display Logic
    func shouldShowBannerAd() -> Bool {
        return !isPremium && !isAdRemovalPurchased
    }
    
    func shouldShowInterstitialAd() -> Bool {
        guard !isPremium && !isAdRemovalPurchased else { return false }
        
        // 前回の広告表示から一定時間経過しているかチェック
        if let lastTime = lastInterstitialAdTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastTime)
            return timeSinceLastAd >= interstitialAdInterval
        }
        
        return true
    }
    
    func recordInterstitialAdShown() {
        lastInterstitialAdTime = Date()
    }
    
    // MARK: - StoreKit 2 Product Loading
    private func loadProducts() async {
        do {
            let productIdentifiers = Set([adRemovalProductID])
            products = try await Product.products(for: productIdentifiers)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Methods
    func purchaseAdRemoval() async {
        guard let product = products.first(where: { $0.id == adRemovalProductID }) else {
            print("Product not found")
            return
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified:
                    // 購入成功
                    await completeAdRemovalPurchase()
                    print("Purchase successful")
                case .unverified:
                    print("Purchase verification failed")
                }
                
            case .userCancelled:
                print("Purchase cancelled by user")
                
            case .pending:
                print("Purchase pending")
                
            @unknown default:
                print("Unknown purchase result")
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            print("Restore failed: \(error)")
        }
    }
    
    private func checkPurchaseStatus() async {
        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified:
                // 検証済みトランザクションが見つかった場合、購入完了処理を実行
                await completeAdRemovalPurchase()
                break
            case .unverified:
                print("Unverified transaction found")
            }
        }
    }
    
    // MARK: - Purchase Completion
    private func completeAdRemovalPurchase() async {
        isPremium = true
        isAdRemovalPurchased = true
        savePremiumStatus()
    }
} 