// Shared types for Edge Functions

export interface PendingTransaction {
  type: "expense" | "income";
  amount: number;
  currency: string | null;
  category: string;
  language: string;
  description: string;
  timestamp: number;
  datetime: string | null;
}

export interface ParsedTransaction {
  type: "expense" | "income";
  amount: number;
  currency: string | null;
  category: string;
  description: string;
  responseText: string;
  language: string;
  datetime: string | null;
}

export interface UserCategory {
  id: string; // cloudId
  title: string;
  transactionType: string; // "expense" or "income"
  localizedTitles?: Record<string, string>;
}

export interface Wallet {
  cloud_id: string;
  name: string;
  currency: string;
  balance: number;
  is_default: boolean;
}

export interface Transaction {
  cloud_id: string;
  amount: number;
  type: string;
  category_id: string;
  wallet_id: string;
  description: string | null;
  created_at: string;
  transaction_date: string;
}

export interface Localization {
  expense: string;
  income: string;
  recorded: string;
  from: string;
  to: string;
  categories: Record<string, string>;
  cancelled: string;
  linkFirst: string;
  noWallet: string;
  noCategory: string;
  conversionFailed: string;
  addMore: string;
  balance: string;
  expenseDetected: string;
  incomeDetected: string;
  confirm: string;
  cancel: string;
}

export const LOCALIZATIONS: Record<string, Localization> = {
  en: {
    expense: "expense",
    income: "income",
    recorded: "Recorded",
    from: "from",
    to: "to",
    categories: {
      "Food & Drinks": "Food & Drinks",
      "Transportation": "Transportation",
      "Housing": "Housing",
      "Entertainment": "Entertainment",
      "Health": "Health",
      "Shopping": "Shopping",
      "Education": "Education",
      "Travel": "Travel",
      "Finance": "Finance",
      "Utilities": "Utilities",
      "Other": "Other",
    },
    cancelled: "Cancelled",
    linkFirst: "Please link your Bexly account first",
    noWallet: "No wallet found. Create one in Bexly app first.",
    noCategory: "No category found. Create one in Bexly app first.",
    conversionFailed: "Currency conversion failed",
    addMore: "Add more",
    balance: "Balance",
    expenseDetected: "Expense Detected",
    incomeDetected: "Income Detected",
    confirm: "Confirm",
    cancel: "Cancel",
  },
  vi: {
    expense: "chi tiêu",
    income: "thu nhập",
    recorded: "Đã ghi nhận",
    from: "từ",
    to: "vào",
    categories: {
      "Food & Drinks": "Ăn uống",
      "Transportation": "Di chuyển",
      "Housing": "Nhà ở",
      "Entertainment": "Giải trí",
      "Health": "Sức khỏe",
      "Shopping": "Mua sắm",
      "Education": "Giáo dục",
      "Travel": "Du lịch",
      "Finance": "Tài chính",
      "Utilities": "Tiện ích",
      "Other": "Khác",
    },
    cancelled: "Đã hủy",
    linkFirst: "Vui lòng liên kết tài khoản Bexly trước",
    noWallet: "Không tìm thấy ví. Tạo ví trong ứng dụng Bexly trước.",
    noCategory: "Không tìm thấy danh mục. Tạo trong ứng dụng Bexly trước.",
    conversionFailed: "Chuyển đổi tiền tệ thất bại",
    addMore: "Thêm nữa",
    balance: "Số dư",
    expenseDetected: "Phát hiện chi tiêu",
    incomeDetected: "Phát hiện thu nhập",
    confirm: "Xác nhận",
    cancel: "Hủy",
  },
};

export type AIProvider = "gemini" | "openai" | "claude";

export const AI_CONFIG = {
  provider: "gemini" as AIProvider,
  models: {
    gemini: "gemini-2.0-flash-exp",
    openai: "gpt-4o-mini",
    claude: "claude-sonnet-4-20250514",
  },
};
