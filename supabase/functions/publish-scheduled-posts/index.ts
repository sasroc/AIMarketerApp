// Supabase Edge Function for publishing scheduled Instagram posts
// This function should be triggered by a cron job (e.g., every 5 minutes)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const GRAPH_API_BASE_URL = "https://graph.facebook.com/v18.0";

interface PostToPublish {
  post_id: string;
  user_id: string;
  caption: string;
  media_url: string;
  media_type: string;
  scheduled_date: string;
}

interface InstagramConnection {
  instagram_user_id: string;
  instagram_username: string;
  access_token: string;
  token_expires_at: string;
  is_connected: boolean;
}

serve(async (req) => {
  try {
    // Initialize Supabase client with service role key (has admin privileges)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    console.log("🤖 Starting scheduled post publishing job...");

    // Get posts that are ready to be published
    const { data: posts, error: postsError } = await supabase
      .rpc("get_posts_ready_for_publishing");

    if (postsError) {
      console.error("❌ Error fetching posts:", postsError);
      throw postsError;
    }

    if (!posts || posts.length === 0) {
      console.log("✅ No posts to publish at this time");
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "No posts to publish",
          published: 0 
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`📋 Found ${posts.length} post(s) ready to publish`);

    const results = {
      total: posts.length,
      published: 0,
      failed: 0,
      errors: [] as string[],
    };

    // Process each post
    for (const post of posts as PostToPublish[]) {
      try {
        console.log(`\n📸 Processing post ${post.post_id}`);

        // Get user's Instagram connection
        const { data: connection, error: connectionError } = await supabase
          .from("instagram_connections")
          .select("*")
          .eq("user_id", post.user_id)
          .single();

        if (connectionError || !connection) {
          console.error(`❌ No Instagram connection for user ${post.user_id}`);
          await updatePostFailed(
            supabase,
            post.post_id,
            "Instagram account not connected"
          );
          results.failed++;
          results.errors.push(`Post ${post.post_id}: No Instagram connection`);
          continue;
        }

        const igConnection = connection as InstagramConnection;

        // Check if token is expired
        const tokenExpiry = new Date(igConnection.token_expires_at);
        if (tokenExpiry < new Date()) {
          console.error(`❌ Token expired for user ${post.user_id}`);
          await updatePostFailed(
            supabase,
            post.post_id,
            "Instagram access token expired. Please reconnect your account."
          );
          results.failed++;
          results.errors.push(`Post ${post.post_id}: Token expired`);
          continue;
        }

        // Check if Instagram connection is active
        if (!igConnection.is_connected) {
          console.error(`❌ Instagram disconnected for user ${post.user_id}`);
          await updatePostFailed(
            supabase,
            post.post_id,
            "Instagram account disconnected"
          );
          results.failed++;
          results.errors.push(`Post ${post.post_id}: Account disconnected`);
          continue;
        }

        // Determine media type from database field
        const isVideo = post.media_type === 'video';

        console.log(`📤 Publishing ${isVideo ? "video" : "image"} to Instagram...`);

        // Publish to Instagram
        const publishResult = await publishToInstagram(
          igConnection.instagram_user_id,
          post.media_url,
          post.caption,
          igConnection.access_token,
          isVideo
        );

        if (publishResult.success) {
          // Update post as published
          await supabase.rpc("update_post_after_publishing", {
            p_post_id: post.post_id,
            p_instagram_post_id: publishResult.postId,
            p_instagram_permalink: publishResult.permalink || null,
            p_success: true,
            p_error_message: null,
          });

          console.log(`✅ Post ${post.post_id} published successfully as ${publishResult.postId}`);
          results.published++;
        } else {
          // Update post as failed
          await updatePostFailed(
            supabase,
            post.post_id,
            publishResult.error || "Unknown error"
          );
          console.error(`❌ Failed to publish post ${post.post_id}: ${publishResult.error}`);
          results.failed++;
          results.errors.push(`Post ${post.post_id}: ${publishResult.error}`);
        }
      } catch (error) {
        console.error(`❌ Error processing post ${post.post_id}:`, error);
        await updatePostFailed(
          supabase,
          post.post_id,
          error.message || "Unknown error"
        );
        results.failed++;
        results.errors.push(`Post ${post.post_id}: ${error.message}`);
      }

      // Add a small delay between posts to avoid rate limiting
      await new Promise((resolve) => setTimeout(resolve, 2000));
    }

    console.log("\n📊 Publishing job complete:");
    console.log(`   ✅ Published: ${results.published}`);
    console.log(`   ❌ Failed: ${results.failed}`);
    console.log(`   📝 Total: ${results.total}`);

    return new Response(
      JSON.stringify({
        success: true,
        results,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Fatal error in publishing job:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

/**
 * Publish a post to Instagram via Graph API
 */
async function publishToInstagram(
  instagramUserId: string,
  mediaUrl: string,
  caption: string,
  accessToken: string,
  isVideo: boolean
): Promise<{ success: boolean; postId?: string; permalink?: string; error?: string }> {
  try {
    // Step 1: Create media container
    console.log(`   Creating ${isVideo ? "video" : "image"} container...`);
    const containerParams = new URLSearchParams({
      access_token: accessToken,
      caption: caption,
    });

    if (isVideo) {
      containerParams.append("media_type", "REELS");
      containerParams.append("video_url", mediaUrl);
    } else {
      containerParams.append("image_url", mediaUrl);
    }

    const containerResponse = await fetch(
      `${GRAPH_API_BASE_URL}/${instagramUserId}/media?${containerParams.toString()}`,
      { method: "POST" }
    );

    if (!containerResponse.ok) {
      const error = await containerResponse.json();
      console.error("   ❌ Container creation failed:", error);
      return {
        success: false,
        error: error.error?.message || "Failed to create media container",
      };
    }

    const containerData = await containerResponse.json();
    const containerId = containerData.id;
    console.log(`   ✅ Container created: ${containerId}`);

    // Step 2: For videos, wait for processing
    if (isVideo) {
      console.log(`   ⏳ Waiting for video processing...`);
      const processingResult = await waitForVideoProcessing(
        containerId,
        accessToken
      );
      
      if (!processingResult.success) {
        return {
          success: false,
          error: processingResult.error || "Video processing failed",
        };
      }
      console.log(`   ✅ Video processing complete`);
    }

    // Step 3: Publish the container
    console.log(`   Publishing container...`);
    const publishParams = new URLSearchParams({
      creation_id: containerId,
      access_token: accessToken,
    });

    const publishResponse = await fetch(
      `${GRAPH_API_BASE_URL}/${instagramUserId}/media_publish?${publishParams.toString()}`,
      { method: "POST" }
    );

    if (!publishResponse.ok) {
      const error = await publishResponse.json();
      console.error("   ❌ Publishing failed:", error);
      return {
        success: false,
        error: error.error?.message || "Failed to publish media",
      };
    }

    const publishData = await publishResponse.json();
    const postId = publishData.id;
    
    // Get permalink
    const permalink = await getPostPermalink(postId, accessToken);
    
    console.log(`   ✅ Published successfully: ${postId}`);

    return {
      success: true,
      postId,
      permalink,
    };
  } catch (error) {
    console.error("   ❌ Exception during publishing:", error);
    return {
      success: false,
      error: error.message || "Unknown error",
    };
  }
}

/**
 * Wait for video processing to complete (with timeout)
 */
async function waitForVideoProcessing(
  containerId: string,
  accessToken: string,
  maxAttempts: number = 30
): Promise<{ success: boolean; error?: string }> {
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      const statusParams = new URLSearchParams({
        fields: "status_code",
        access_token: accessToken,
      });

      const response = await fetch(
        `${GRAPH_API_BASE_URL}/${containerId}?${statusParams.toString()}`
      );

      if (!response.ok) {
        return { success: false, error: "Failed to check video status" };
      }

      const data = await response.json();
      const status = data.status_code;

      if (status === "FINISHED") {
        return { success: true };
      } else if (status === "ERROR") {
        return { success: false, error: "Video processing error" };
      }

      // Still processing, wait 10 seconds
      console.log(`   ⏳ Video processing... (attempt ${attempt + 1}/${maxAttempts})`);
      await new Promise((resolve) => setTimeout(resolve, 10000));
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  return { success: false, error: "Video processing timeout" };
}

/**
 * Get the permalink for a published post
 */
async function getPostPermalink(
  postId: string,
  accessToken: string
): Promise<string | undefined> {
  try {
    const params = new URLSearchParams({
      fields: "permalink",
      access_token: accessToken,
    });

    const response = await fetch(
      `${GRAPH_API_BASE_URL}/${postId}?${params.toString()}`
    );

    if (response.ok) {
      const data = await response.json();
      return data.permalink;
    }
  } catch (error) {
    console.error("   ⚠️ Could not fetch permalink:", error);
  }
  
  return undefined;
}

/**
 * Update post status as failed
 */
async function updatePostFailed(
  supabase: any,
  postId: string,
  errorMessage: string
): Promise<void> {
  await supabase.rpc("update_post_after_publishing", {
    p_post_id: postId,
    p_instagram_post_id: null,
    p_instagram_permalink: null,
    p_success: false,
    p_error_message: errorMessage,
  });
}



