import React from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import i18n from "i18next";
import { useTranslation } from "react-i18next";


export const UrineAcid : React.FC = () => {
    const { t } = useTranslation('translation')
    console.log("Urine acid render")

    i18n.addResource('gb', 'translation', 'urine_acid', 'Urine acid');
    i18n.addResource('de', 'translation', 'urine_acid', 'Zucker');
    i18n.addResource('pl', 'translation', 'urine_acid', 'Kwas moczowy');

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
            <Toolbar>
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('urine_acid')}
                </Typography>
            </Toolbar>
        </Container>
        </AppBar>
    )
}