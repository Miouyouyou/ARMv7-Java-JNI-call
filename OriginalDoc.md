# Example of calling Java methods through the JNI, in ARM Assembly, on Android

Author : **Myy**

This document demonstrates how to call the JNI, through a procedure :
* written with the GNU ARM Assembly syntax,
* assembled and stored in a ELF shared library,
* executed by an Android system through an Android Activity.

The procedure will be called by an Android app and will
* build a Java String from an array of 16 bits values representing UTF16-LE encoded characters,
* retrieve a Java method,
* execute this Java method with the built Java String as an argument.

The executed Java method will display our super secret String to the user&#39;s screen, through the Android App.

This document complements [Example of calling the JNI directly from ARM Assembly on Android]().

### Quick reminder

The JNI always pass :
* a pointer to a `_JNIEnv` structure as the first argument, **r0**
* a pointer to the object which received the method call as the second argument, **r1**

Then, it will pass the other arguments in **r2**, **r3** and the stack (**sp**)

### Settings used in this example

This example uses the following settings :
* Java package name `adventurers.decyphering.secrets.decyphapp`
* Java class name `DecypherActivity`
* Java native method name `decypherArcaneSecrets`

Therefore, the method name using the Java_package_name_ClassName_methodName pattern will be :

`Java_adventurers_decyphering_secrets_decyphapp_DecypherActivity_decypherArcaneSecrets`

### GNU ARM Assembly code

**decypherArcane.S**

```gas_arm

.data
java_method_name:
  .ascii "revealTheSecret"
java_method_signature:
  .ascii "(Ljava/lang/String;)V"

; Our UTF16-LE encoded secret message
secret:
  .hword 55357, 56892, 85, 110, 32, 99, 104, 97, 116, 10
  .hword 55357, 56377, 12495, 12512, 12473, 12479, 12540, 10
  .hword 55357, 56360, 27193, 29066, 10
  .hword 55357, 56445, 65, 110, 32, 97, 108, 105, 101, 110, 10
secret_len = . - secret
secret_len = secret_len / 2  ; 2 bytes per character

.text
.align 2
.globl Java_adventurers_decyphering_secrets_decyphapp_DecypherActivity_decypherArcaneSecrets
.type Java_adventurers_decyphering_secrets_decyphapp_DecypherActivity_decypherArcaneSecrets, %function
Java_adventurers_decyphering_secrets_decyphapp_DecypherActivity_decypherArcaneSecrets:
  push {r4-r7, lr} ; Prologue. We will use r4, r5, r6, r7

  ; Passed parameters - r0 : *_JNIEnv, r1 : thisObject

  mov r4, r0   ; r4 : Backup of *JNIEnv as we'll use it very often
  mov r5, r1   ; r5 : Backup of thisObject as we'll invoke methods on it
  ldr r6, [r0] ; r6 : Backup of *_JNINativeInterface, located at *_JNIEnv,
               ;      since we'll also use it a lot

  ; Preparing to call NewString(*_JNIEnv : r0, *string_characters : r1, string_length : r2).
  ; *_JNIEnv is already loaded.

  ldr r1, =secret     ; r1 : The UTF16-LE characters composing the java.lang.String
  mov r2, #secret_len ; r2 : The length of the String
  ldr r3, [r6, #652]  ; Get *JNINativeInterface->NewString. +652 is NewString's offset
  blx r3              ; secret_string : r0 <- NewString(*_JNIEnv : r0, *string_characters : r1, string_length : r2)
  mov r7, r0          ; r7 : secret_string - Keep the returned string for later use

  ; Calling showText(java.lang.String) through the JNI
  ;
  ; First : We need the class of thisObject. We could pass it directly
  ; to the procedure but, for learning purposes, we'll use JNI methods
  ; to get it.

  ; Preparing to call GetObjectClass(*_JNIEnv : r0, thisObject : r1)
  mov r0, r4         ; r0 : *_JNIEnv
  mov r1, r5         ; r1 : thisObject
  ldr r2, [r6, #124] ; Get *JNINativeInterface->GetObjectClass (+124)
  blx r2             ; jclass : r0 <- GetObjectClass(r0 : *JNIEnv, r1 : thisObject)

  ; Second : We need the JNI ID of the method we want to call
  ; Preparing for GetMethodId(r0 : *JNIEnv, r1 : jclass, r2 : method_name, r3 : method_signature)
  mov r1, r0 ; r1 : jclass returned by GetObjectClass
  mov r0, r4 ; r0 : *JNIEnv, previously backed up in r4
  ldr r2, =java_method_name      ; r2 : The method name
  ldr r3, =java_method_signature ; r3 : The method signature
  ldr r8, [r6, #132]             ; Get *JNINativeInterface->GetMethodId (+132)
  blx r8     ; revealTheSecretID : r0 <- GetMethodId(*_JNIEnv : r0, jclass : r1, method_name : r2, method_signature : r3)

  ; Finally : Call the method. Since it's a method returning void, we'll use CallVoidMethod.
  ; Preparing to call CallVoidMethod(*_JNIEnv : r0, thisObject : r1, revealTheSecretID : r2, secret_string : r3)
  mov r2, r0         ; r2 : revealTheSecretID : Backup the ID for later
  mov r1, r5         ; r1 : thisObject
  mov r0, r4         ; r0 : *_JNIEnv
  mov r3, r7         ; r3 : secret_string
  ldr r8, [r6, #244] ; Get *_JNINativeInterface->CallVoidMethod (+244).
  blx r8 ; CallVoidMethod(*_JNIEnv : r0, thisObject : r1, revealTheSecretID : r2, the_string : r3)
         ; -> revealTheSecret(the_string)

  pop {r4-r7, pc} ; Restoring the scratch-registers and returning by loading the link-register into the program-counter

```


### Android&#39;s Java code

**DecypherActivity.java**

```java


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

```


### Android&#39;s Activity

**activity_decypher.xml**

```xml


<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
   xmlns:tools="http://schemas.android.com/tools"
   android:layout_width="match_parent"
   android:layout_height="match_parent"
   android:background="#0099cc"
   tools:context="adventurers.decyphering.secrets.decyphapp.DecypherActivity"
  >

  <!-- The primary full-screen view. This can be replaced with whatever view
  is needed to present your content, e.g. VideoView, SurfaceView,
  TextureView, etc. -->
  <TextView
   android:id="@+id/fullscreen_content"
   android:layout_width="match_parent"
   android:layout_height="match_parent"
   android:gravity="center"
   android:keepScreenOn="true"
   android:textColor="#33b5e5"
   android:textSize="50sp"
   android:textStyle="bold"
   />

</FrameLayout>


```


### Linking and installation from a Unix shell

```

export PREFIX="armv7a-hardfloat-linux-gnueabi"
export APP_DIR="/tmp/DecyphApp"
export LIBNAME="libarcane.so"
$PREFIX-as -o decypherArcane.o decypherArcane.S
$PREFIX-ld.gold -shared --dynamic-linker=/system/bin/linker -shared --hash-style=sysv -o $LIBNAME decypherArcane.o
mkdir -p $APP_DIR/app/src/main/jniLibs/armeabi{,-v7a}
cp $LIBNAME $APP_DIR/app/src/main/jniLibs/armeabi
cp $LIBNAME $APP_DIR/app/src/main/jniLibs/armeabi-v7a
cd $APP_DIR
./gradlew installDebug

```


### A note on Java method descriptors

Guessing the descriptor of a Java method is not trivial. Since the JNI want the internal type codes of the parameters types AND the return type, this is even more complex.

As stated in the official documentation, the internal descriptor of Java methods is as follows :

    (parameters Types codes without spaces)return Type code

The codes associated to Java Types are :

Java type|Internal code|
---|---|
void|V|
boolean|Z|
byte|B|
char|C|
short|S|
int|I|
long|J|
float|F|
double|D|
Array|[component_code|
Class|Lfully/qualified/name;|




> The semicolon after the fully qualified name of a Class is essential.



> There is no right square bracket in Array codes.

So, for example, a Java method declared like this :`void a(int a, long b, String c, HashMap[] d, boolean e)`

has the following descriptor :`(IJLjava/lang/String;[Ljava/util/HashMap;Z)V`

One way to obtain that kind of informations is to use javap on your class :`<command>javap -s your/package/name/Class</command>`

Which will output something like :

```
Compiled from "Filename.java"



    ...



    void a(int, long, java.lang.String, java.util.HashMap[], boolean);

        descriptor: (IJLjava/lang/String;[Ljava/util/HashMap;Z)V



    ...
```


However, using 

Another way is to create a little library like this. I&#39;ll call it `MethodsHelpers` here.

**MethodsHelpers.java**

```java


package your.package.name;

import java.lang.reflect.Method;
import java.util.HashMap;

import android.util.Log;

public class MethodsHelpers {

  static public HashMap<Class, String> primitive_types_codes;
  static public String LOG_TAG = "MY_APP";

  static {
    primitive_types_codes = new HashMap<Class,String>();
    primitive_types_codes.put(void.class,    "V");
    primitive_types_codes.put(boolean.class, "Z");
    primitive_types_codes.put(byte.class,    "B");
    primitive_types_codes.put(short.class,   "S");
    primitive_types_codes.put(char.class,    "C");
    primitive_types_codes.put(int.class,     "I");
    primitive_types_codes.put(long.class,    "J");
    primitive_types_codes.put(float.class,   "F");
    primitive_types_codes.put(double.class,  "D");
  }

  public static String code_of(final Class class_object) {
    final StringBuilder class_name_builder = new StringBuilder(20);
    Class component_class = class_object;
    while (component_class.isArray()) {
      class_name_builder.append("[");
      component_class = component_class.getComponentType();
    }
    if (component_class.isPrimitive())
      class_name_builder.append(primitive_types_codes.get(component_class));
    else {
      class_name_builder.append("L");
      class_name_builder.append(
        component_class.getCanonicalName().replace(".", "/")
      );
      class_name_builder.append(";");
    }
    return class_name_builder.toString();
  }

  public static void print_methods_descriptors_of(Class analysed_class) {
    StringBuilder descriptor_builder = new StringBuilder(32);
    Method[] methods = analysed_class.getDeclaredMethods();
    for (Method meth : methods) {
      descriptor_builder.append("(");

      for (Class param_class : meth.getParameterTypes())
        descriptor_builder.append(code_of(param_class));

      descriptor_builder.append(")");

      descriptor_builder.append(code_of(meth.getReturnType()));

      Log.d(LOG_TAG,
            String.format("%s\n"+
                          "Name       : %s\n"+
                          "Descriptor : %s\n\n",
                          meth.toString(),
                          meth.getName(),
                          descriptor_builder.toString())
      );

      descriptor_builder.delete(0, descriptor_builder.length());
    }
  }

}


```


Then import it and use it like this :

```java

import static your_package_name.MethodHelpers.print_methods_descriptors_of;

...

print_methods_descriptors_of(AnalysedClass.class);

```


Then run it, look at your logs and you should see something like :

```

    D/MY_APP  (22564): void your.package.name.a(int,long,java.lang.String,java.util.HashMap[],boolean)

    D/MY_APP  (22564): Name       : a

    D/MY_APP  (22564): Descriptor : (IJLjava/lang/String;[Ljava/util/HashMap;Z)V
```


### What about constructors ?

In order to construct objects through the JNI, you&#39;ll need to :
* Get the methodID of the constructor by using `GetMethodId(_JNIEnv* : r0, jclass : r1, <init> : r2, constructor_descriptor : r3)`. Note that constructors always return `void`.
* Use `NewObject(_JNIEnv* : r0, jclass : r1, jmethodID : r2, ...);` (offset +112) to construct the object
