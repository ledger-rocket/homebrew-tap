class RocketReview < Formula
  include Language::Python::Virtualenv

  desc "Second-opinion code and plan reviews from Codex, Claude Code, or opencode"
  homepage "https://github.com/ledger-rocket/rocket-review"
  url "https://files.pythonhosted.org/packages/52/d9/94a2c946a15f952ca7f87bd89a5fff39800f5c9c7a4ba5b6fb5a5487510c/rocket_review-0.3.2.tar.gz"
  sha256 "06d1654bc19ce4f034cc91312090df3a58da4f570ed453750af2c7986d7afc85"
  license "Apache-2.0"

  depends_on "python@3.13"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rr --version")
  end
end
