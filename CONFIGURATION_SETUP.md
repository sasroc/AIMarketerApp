# Configuration Setup

## 🔐 Setting Up Your Supabase Credentials

To use the AI functionality, you need to configure your Supabase credentials securely.

### **Step 1: Copy the Template**

```bash
cp Config.template.plist Config.plist
```

### **Step 2: Edit Config.plist**

Open `Config.plist` and replace the placeholder values:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SupabaseURL</key>
	<string>https://your-project-id.supabase.co</string>
	<key>SupabaseKey</key>
	<string>your-supabase-anon-key-here</string>
</dict>
</plist>
```

### **Step 3: Get Your Credentials**

1. Go to [supabase.com](https://supabase.com) and sign in
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → Replace `https://your-project-id.supabase.co`
   - **Project API Key (anon/public)** → Replace `your-supabase-anon-key-here`

### **Step 4: Verify Setup**

Build and run your app. If configured correctly, the AI functionality will work. If not, you'll see a clear error message.

## 🔒 Security Notes

- ✅ `Config.plist` is in `.gitignore` - your credentials won't be committed
- ✅ `Config.template.plist` is safe to commit (contains no real credentials)
- ✅ The app will crash with a clear error if credentials are missing

## 🚨 Important

**Never commit `Config.plist` to git!** It contains your actual Supabase credentials.

## 📁 File Structure

```
AIMarketerApp/
├── Config.plist          # ← Your actual credentials (DO NOT COMMIT)
├── Config.template.plist # ← Template file (safe to commit)
└── .gitignore           # ← Excludes Config.plist from git
```
