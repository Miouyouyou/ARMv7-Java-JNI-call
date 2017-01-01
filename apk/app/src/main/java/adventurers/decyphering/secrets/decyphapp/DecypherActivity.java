package adventurers.decyphering.secrets.decyphapp;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.TextView;

public class DecypherActivity extends AppCompatActivity {

  static { System.loadLibrary("arcane"); }
  native void decypherArcaneSecrets();

  TextView mContentView;

  public void revealTheSecret(String text) {
    mContentView.setText(text);
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    setContentView(R.layout.activity_decypher);

    mContentView = (TextView) findViewById(R.id.fullscreen_content);
    decypherArcaneSecrets();
  }
}
