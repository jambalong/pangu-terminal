class AddCommentToApiKeysToken < ActiveRecord::Migration[8.1]
  def change
    change_column_comment :api_keys, :token, from: nil, to: "SHA-256 digest of the raw token"
  end
end
