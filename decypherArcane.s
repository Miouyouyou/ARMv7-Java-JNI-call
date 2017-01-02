.data
java_method_name:
	.asciz "revealTheSecret"
java_method_signature:
	.asciz "(Ljava/lang/String;)V"

@ Our UTF16-LE encoded secret message
secret:
	.hword 55357, 56892, 85, 110, 32, 99, 104, 97, 116, 10
	.hword 55357, 56377, 12495, 12512, 12473, 12479, 12540, 10
	.hword 55357, 56360, 27193, 29066, 10
	.hword 55357, 56445, 65, 110, 32, 97, 108, 105, 101, 110, 10
secret_len = . - secret
secret_len = secret_len / 2  /* 2 bytes per character */

.text
.align 2
.globl Java_adventurers_decyphering_secrets_decyphapp_DecypherActivity_decypherArcaneSecrets
.type Java_adventurers_decyphering_secrets_decyphapp_DecypherActivity_decypherArcaneSecrets, %function
Java_adventurers_decyphering_secrets_decyphapp_DecypherActivity_decypherArcaneSecrets:
	push {r4-r7, lr} @ Prologue. We will use r4, r5, r6, r7

	@ Passed parameters - r0 : *_JNIEnv, r1 : thisObject

	mov r4, r0   @ r4 : Backup of *JNIEnv as we'll use it very often
	mov r5, r1   @ r5 : Backup of thisObject as we'll invoke methods on it
	ldr r6, [r0] @ r6 : Backup of *_JNINativeInterface, located at *_JNIEnv,
	             @      since we'll also use it a lot

	/* Preparing to call NewString(*_JNIEnv : r0, 
	                     *string_characters : r1, 
	                          string_length : r2).
	   *_JNIEnv is still in r0.
	*/

	ldr r1, =secret     @ r1 : The UTF16-LE characters composing 
	                    @      the java.lang.String
	mov r2, #secret_len @ r2 : The length of the String
	ldr r3, [r6, #652]  @ Get *JNINativeInterface->NewString. 
	                    @ +652 is NewString's offset
	blx r3              @ secret_string : r0 <- NewString(*_JNIEnv : r0, 
	                    @                       *string_characters : r1,
	                    @                            string_length : r2)
	mov r7, r0          @ r7 : secret_string
	                    @ Keep the returned string for later use

	/* Calling showText(java.lang.String) through the JNI
	
	   First : We need the class of thisObject. We could pass it directly
	   to the procedure but, for learning purposes, we'll use JNI methods
	   to get it.
	*/

	@ Preparing to call GetObjectClass(*_JNIEnv : r0, thisObject : r1)
	mov r0, r4         @ r0 : *_JNIEnv
	mov r1, r5         @ r1 : thisObject
	ldr r2, [r6, #124] @ Get *JNINativeInterface->GetObjectClass (+124)
	blx r2             @ jclass : r0 <- GetObjectClass(*JNIEnv : r0, 
	                   @                            thisObject : r1)
	/* Second : We need the JNI ID of the method we want to call
	   Preparing for GetMethodId(*JNIEnv : r0, 
	                              jclass : r1, 
	                         method_name : r2, 
	                    method_signature : r3)
	*/

	mov r1, r0 @ r1 : jclass returned by GetObjectClass
	mov r0, r4 @ r0 : *JNIEnv, previously backed up in r4
	ldr r2, =java_method_name      @ r2 : The method name
	ldr r3, =java_method_signature @ r3 : The method signature
	ldr r8, [r6, #132]             @ Get *JNINativeInterface->GetMethodId
	                               @ (+132)
	blx r8     @ revealTheSecretID : r0 <- GetMethodId(*_JNIEnv : r0, 
	           @                                         jclass : r1, 
	           @                                    method_name : r2, 
	           @                               method_signature : r3)

	@ Finally : Call the method. Since it's a method returning void, 
	@ we'll use CallVoidMethod.
	@ Preparing to call CallVoidMethod(*_JNIEnv : r0, 
	@                                thisObject : r1,
	@                         revealTheSecretID : r2,
	@                             secret_string : r3)

	mov r2, r0         @ r2 : revealTheSecretID : Backup the ID for later
	mov r1, r5         @ r1 : thisObject
	mov r0, r4         @ r0 : *_JNIEnv
	mov r3, r7         @ r3 : secret_string
	ldr r8, [r6, #244] @ Get *_JNINativeInterface->CallVoidMethod (+244).
	blx r8 @ CallVoidMethod(*_JNIEnv : r0, 
	       @              thisObject : r1,
	       @       revealTheSecretID : r2,
	       @              the_string : r3)
	       @ => Java : revealTheSecret(the_string)

	pop {r4-r7, pc} @ Restoring the scratch-registers and 
	                @ returning by loading the link-register 
	                @ into the program-counter
