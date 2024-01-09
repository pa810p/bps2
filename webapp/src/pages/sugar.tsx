import React, { useState } from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import i18n from "i18next";
import { useTranslation } from "react-i18next";
import TextField from "@mui/material/TextField";
import Button from "@mui/material/Button";


export const Sugar : React.FC = () => {
    const { t } = useTranslation('translation')
    console.log("Sugar render")

    i18n.addResource('gb', 'translation', 'sugar', 'Sugar');
    i18n.addResource('de', 'translation', 'sugar', 'Zucker');
    i18n.addResource('pl', 'translation', 'sugar', 'Cukier');

    i18n.addResource('gb', 'translation', 'ok', 'OK');
    i18n.addResource('de', 'translation', 'ok', 'OK');
    i18n.addResource('pl', 'translation', 'ok', 'OK');

    i18n.addResource('gb', 'translation', 'comment', 'Comment');
    i18n.addResource('de', 'translation', 'comment', 'Kommentar');
    i18n.addResource('pl', 'translation', 'comment', 'Uwagi');


    const [valid, setValid] = useState(false)
    // const [memValid] = useMemo( () => {
    //     return [valid];
    //  }, [valid] );

    // let valid = false;
    
    const handleSugarLevelValidation = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        const reg = /^[0-2]?\d{2}$/;

        console.log(e.target.value);
        setValid(reg.test(e.target.value));
        // valid = reg.test(e.target.value)
    }

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
            <Toolbar>
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('sugar')}
                </Typography>
                <TextField
                    onChange={(event) => handleSugarLevelValidation(event)}
                    label="Sugar level [mg/dL]"
                    variant="outlined"
                    error={!valid}
                    sx={{ mb: 2 }}
                    />
                    {/* <Button color="inherit">{t('add')}</Button> */}
                <TextField
                    label={t('comment')}
                    variant="outlined"
                    sx={{mb: 2}}
                    />
                <Button color="inherit">{t('ok')}</Button>
            </Toolbar>
        </Container>
        </AppBar>
    )
}