# Adding AI Image Generation Files to Xcode

This guide shows you how to add the new AI image generation files to your Xcode project.

## Files to Add

You need to add 2 new Swift files to your Xcode project:

1. `AIMarketerApp/Services/AIImageGenerationService.swift`
2. `AIMarketerApp/Views/Campaign/AIImageGenerationSection.swift`

## Step-by-Step Instructions

### Adding AIImageGenerationService.swift

1. **Open Xcode**
   - Open `AIMarketerApp.xcodeproj`

2. **Navigate to Services Group**
   - In the Project Navigator (left sidebar)
   - Find the "Services" folder under "AIMarketerApp"

3. **Add the File**
   - Right-click on "Services" folder
   - Select "Add Files to 'AIMarketerApp'..."
   - Navigate to: `AIMarketerApp/Services/`
   - Select: `AIImageGenerationService.swift`
   - **Important Settings:**
     - ✅ Check "Copy items if needed"
     - ✅ Ensure "AIMarketerApp" target is checked
     - Options: "Create groups" (default)
   - Click "Add"

4. **Verify**
   - You should see `AIImageGenerationService.swift` in the Services folder
   - It should have the target membership icon (not grayed out)

### Adding AIImageGenerationSection.swift

1. **Navigate to Campaign Views Group**
   - In the Project Navigator
   - Find "Views" → "Campaign" folder

2. **Add the File**
   - Right-click on "Campaign" folder
   - Select "Add Files to 'AIMarketerApp'..."
   - Navigate to: `AIMarketerApp/Views/Campaign/`
   - Select: `AIImageGenerationSection.swift`
   - **Important Settings:**
     - ✅ Check "Copy items if needed"
     - ✅ Ensure "AIMarketerApp" target is checked
     - Options: "Create groups" (default)
   - Click "Add"

3. **Verify**
   - You should see `AIImageGenerationSection.swift` in the Campaign folder
   - It should be grouped with other section files like `MediaUploadSection.swift`

## Verifying the Files Are Added Correctly

### Method 1: Build the Project

1. Press `⌘B` or select "Product" → "Build"
2. Check for any compilation errors
3. If successful, the files are properly integrated

### Method 2: Check Target Membership

1. Select `AIImageGenerationService.swift` in Project Navigator
2. Open File Inspector (right sidebar, first tab)
3. Under "Target Membership", ensure "AIMarketerApp" is checked
4. Repeat for `AIImageGenerationSection.swift`

### Method 3: Check Compile Sources

1. Select your project in Project Navigator (top item)
2. Select "AIMarketerApp" target
3. Go to "Build Phases" tab
4. Expand "Compile Sources"
5. Verify both new files are listed:
   - `AIImageGenerationService.swift`
   - `AIImageGenerationSection.swift`

## Common Issues and Solutions

### Issue: "Cannot find 'AIImageGenerationService' in scope"

**Cause**: File not added to target or not in compile sources

**Solution**:
1. Select the file in Project Navigator
2. Open File Inspector (⌘⌥1)
3. Check "AIMarketerApp" under Target Membership
4. Clean build folder (⌘⇧K)
5. Build again (⌘B)

### Issue: "No such module 'Supabase'"

**Cause**: Package dependencies not resolved

**Solution**:
1. Select your project in Project Navigator
2. Go to "Package Dependencies" tab
3. Click refresh button (⟳) next to each package
4. Wait for packages to resolve
5. Build again (⌘B)

### Issue: Files appear gray or unavailable

**Cause**: Files not copied to project directory

**Solution**:
1. Remove the files from Xcode (right-click → Delete → "Remove Reference")
2. Re-add them with "Copy items if needed" CHECKED
3. Ensure correct target is selected

### Issue: Build succeeds but UI doesn't show new section

**Cause**: `CreateCampaignView.swift` changes not applied

**Solution**:
1. Open `CreateCampaignView.swift`
2. Verify it includes `AIImageGenerationSection()` in the VStack for step 0
3. If not, check that file has been properly updated
4. Clean build (⌘⇧K) and rebuild (⌘B)

## Validating the Integration

After adding the files successfully:

1. **Build succeeds** without errors
2. **Run the app** (⌘R)
3. **Sign in** to your account
4. **Navigate to** Create Campaign
5. **Verify** you see the "AI Image Generation" section at the top
6. **Test generation**:
   - Enter a prompt: "A beautiful sunset over mountains"
   - Select "Square" size
   - Tap "Generate Image"
   - Wait for generation (~15 seconds)
   - Preview should appear

## Project Structure After Adding Files

```
AIMarketerApp/
├── Services/
│   ├── AuthenticationService.swift
│   ├── ContentGenerationService.swift
│   ├── InstagramService.swift
│   ├── SupabaseService.swift
│   └── AIImageGenerationService.swift ✨ NEW
└── Views/
    └── Campaign/
        ├── ContentGuidelinesSection.swift
        ├── CreateCampaignView.swift (modified)
        ├── GeneratedPostsView.swift
        ├── MarketingPlanSection.swift
        ├── MediaUploadSection.swift
        ├── SchedulingSection.swift
        └── AIImageGenerationSection.swift ✨ NEW
```

## Next Steps

Once files are successfully added:

1. ✅ Build the project
2. ✅ Deploy the Edge Function: `./deploy-image-function.sh`
3. ✅ Verify OpenAI API key is set in Supabase
4. ✅ Test on simulator/device
5. ✅ Review `AI_IMAGE_GENERATION_SETUP.md` for usage guide

## Getting Help

If you encounter issues not covered here:

1. **Clean Build Folder**: ⌘⇧K (Product → Clean Build Folder)
2. **Restart Xcode**: Completely quit and reopen
3. **Check File Paths**: Ensure files are in correct directories
4. **Verify Changes**: Check that `CreateCampaignView.swift` includes the new section
5. **Review Errors**: Read build errors carefully - they often indicate the exact issue

## Alternative: Manual File Creation

If adding files doesn't work, you can create them directly in Xcode:

1. **Create AIImageGenerationService.swift**:
   - Right-click Services folder → "New File..."
   - Choose "Swift File"
   - Name it "AIImageGenerationService"
   - Copy content from the created file

2. **Create AIImageGenerationSection.swift**:
   - Right-click Campaign folder → "New File..."
   - Choose "SwiftUI View"
   - Name it "AIImageGenerationSection"
   - Replace content with the created file's content

This ensures files are properly integrated from the start.

## Success Indicators

✅ No build errors
✅ Both files show in Project Navigator
✅ Files have correct target membership
✅ Files appear in Build Phases → Compile Sources
✅ App runs without crashes
✅ AI Image Generation section visible in Create Campaign
✅ Can generate test image successfully

---

**Ready to proceed?** Once files are added, run `./deploy-image-function.sh` and start creating AI-generated images!

