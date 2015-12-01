FactoryGirl.define do
  factory :snapshot do

    association :camera, factory: :camera
    sequence(:notes) { |n| "notes#{n}" }
    created_at Time.at(123456789)
    snapshot_id "2145_20151129181700000"
  end
end
