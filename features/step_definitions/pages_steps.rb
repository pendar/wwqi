Given /^I have pages$/ do
  Fixtures.create_fixtures("spec/fixtures", "pages")
end

Given /^I have no pages$/ do
  # do nothing since we don't want them to load
end
