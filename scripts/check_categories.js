// Quick script to check categories in Supabase
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '../.env' });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'bexly' }
});

async function checkCategories() {
  try {
    // Get user ID from auth (if needed)
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      console.log('No authenticated user');
      return;
    }

    console.log(`\nUser ID: ${user.id}\n`);

    // Check categories count
    const { data: categories, error, count } = await supabase
      .schema('bexly')
      .from('categories')
      .select('cloud_id, title, user_id', { count: 'exact' })
      .eq('user_id', user.id)
      .limit(10);

    if (error) {
      console.error('Error fetching categories:', error);
      return;
    }

    console.log(`Total categories in cloud: ${count}`);
    console.log('\nFirst 10 categories:');
    categories.forEach((cat, i) => {
      console.log(`${i + 1}. ${cat.title} (${cat.cloud_id})`);
    });

  } catch (err) {
    console.error('Error:', err.message);
  }
}

checkCategories();
